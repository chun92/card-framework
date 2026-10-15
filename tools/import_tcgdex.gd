extends SceneTree
## Offline importer for TCGdex card data. Not part of the game; run it by hand.
##
## From the project root:
##   godot --headless --path . --script res://tools/import_tcgdex.gd
##   godot --headless --path . --script res://tools/import_tcgdex.gd -- --sets=base1 --no-images
##
## Options (after "--"):
##   --sets=base1,base2,base3   Sets to import. Default: Base Set, Jungle, Fossil
##   --no-images                Only card data
##   --quality=high|low         Image quality. Default: high
##   --force                    Re-download cards and images that already exist
##   --api=URL                  API root. Default: https://api.tcgdex.net/v2/en
##
## Output:
##   res://data/tcgdex/<set>.json          {"set": {...}, "cards": [...]}
##   res://assets/tcgdex/<set>/<id>.png    Kept out of git by a generated .gitignore
##
## Card objects are stored as the API returns them, except for market prices: "pricing"
## is removed wherever it appears, at the top level and inside "variants_detailed". Prices
## change daily and are not printed card data; keeping them would bury real card changes
## under noise in every diff. Cards reused from an existing file are cleaned the same way,
## so running the importer again cleans files written by older versions without refetching.
## Numbers come back as 50.0 instead of 50 because Godot's JSON parser reads every
## number as float. The values are identical.

const DEFAULT_API := "https://api.tcgdex.net/v2/en"
const DEFAULT_SETS := ["base1", "base2", "base3"]
const DATA_DIR := "res://data/tcgdex"
const IMAGE_DIR := "res://assets/tcgdex"
const PRICING_FIELD := "pricing"
const MAX_ATTEMPTS := 3
const RETRY_DELAY_SEC := 2.0
const REQUEST_DELAY_SEC := 0.05
const HEADERS := ["User-Agent: pokemon-tcg-roguelite-importer", "Accept: application/json"]

var _api: String = DEFAULT_API
var _sets: Array[String] = []
var _with_images: bool = true
var _quality: String = "high"
var _force: bool = false

var _http: HTTPRequest
var _failures: Array[String] = []
var _missing_images: Array[String] = []
var _cards_fetched: int = 0
var _cards_reused: int = 0
var _images_downloaded: int = 0
var _images_skipped: int = 0


func _initialize() -> void:
	_sets.assign(DEFAULT_SETS)
	if not _parse_args():
		quit(2)
		return

	_http = HTTPRequest.new()
	_http.timeout = 30.0
	root.add_child(_http)
	_run.call_deferred()


func _parse_args() -> bool:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--sets="):
			_sets.assign(arg.trim_prefix("--sets=").split(",", false))
		elif arg == "--no-images":
			_with_images = false
		elif arg.begins_with("--quality="):
			_quality = arg.trim_prefix("--quality=")
			if _quality != "high" and _quality != "low":
				printerr("--quality must be high or low")
				return false
		elif arg == "--force":
			_force = true
		elif arg.begins_with("--api="):
			_api = arg.trim_prefix("--api=").trim_suffix("/")
		else:
			printerr("Unknown option: %s" % arg)
			return false
	if _sets.is_empty():
		printerr("No sets given")
		return false
	return true


func _run() -> void:
	var started := Time.get_ticks_msec()
	print("TCGdex import from %s" % _api)
	print("Sets: %s | images: %s | force: %s" % [", ".join(_sets), _quality if _with_images else "no", _force])

	for set_id in _sets:
		await _import_set(set_id)

	print("")
	print("Cards fetched: %d, reused from existing files: %d" % [_cards_fetched, _cards_reused])
	if _with_images:
		print("Images downloaded: %d, already present: %d" % [_images_downloaded, _images_skipped])
	if not _missing_images.is_empty():
		print("Cards without an image in TCGdex: %s" % ", ".join(_missing_images))
	print("Finished in %.1f s" % ((Time.get_ticks_msec() - started) / 1000.0))

	if _failures.is_empty():
		print("OK")
		quit(0)
	else:
		printerr("%d failure(s). Run again to retry only what is missing:" % _failures.size())
		for failure in _failures:
			printerr("  " + failure)
		quit(1)


func _import_set(set_id: String) -> void:
	print("")
	print("== %s" % set_id)

	var set_data := await _get_json_object("%s/sets/%s" % [_api, set_id])
	if set_data.is_empty():
		_failures.append("set %s: could not fetch the set" % set_id)
		return

	var briefs := set_data.get("cards", []) as Array
	set_data.erase("cards")
	print("%s: %d cards" % [set_data.get("name", set_id), briefs.size()])

	var output_path := "%s/%s.json" % [DATA_DIR, set_id]
	var existing := {} if _force else _load_existing_cards(output_path)

	var cards: Array[Dictionary] = []
	for brief_value: Variant in briefs:
		var card_id := str((brief_value as Dictionary).get("id", ""))
		if existing.has(card_id):
			var reused := existing[card_id] as Dictionary
			_strip_pricing(reused)
			cards.append(reused)
			_cards_reused += 1
			continue

		var card := await _get_json_object("%s/cards/%s" % [_api, card_id.uri_encode()])
		if card.is_empty():
			_failures.append("card %s" % card_id)
			continue
		_strip_pricing(card)
		cards.append(card)
		_cards_fetched += 1
		await create_timer(REQUEST_DELAY_SEC).timeout

	cards.sort_custom(_by_local_id)
	if not _write_json(output_path, {"set": set_data, "cards": cards}):
		_failures.append("set %s: could not write %s" % [set_id, output_path])
		return
	print("Wrote %s (%d cards)" % [output_path, cards.size()])

	if _with_images:
		_ensure_image_gitignore()
		for card in cards:
			await _download_image(set_id, card)


## Removes market prices from a card, at the top level and inside every detailed variant.
func _strip_pricing(card: Dictionary) -> void:
	card.erase(PRICING_FIELD)
	var variants: Variant = card.get("variants_detailed")
	if not variants is Array:
		return
	for variant: Variant in variants as Array:
		if variant is Dictionary:
			(variant as Dictionary).erase(PRICING_FIELD)


func _download_image(set_id: String, card: Dictionary) -> void:
	var card_id := str(card.get("id", ""))
	var base_url := str(card.get("image", ""))
	if base_url.is_empty():
		_missing_images.append(card_id)
		return

	var path := "%s/%s/%s.png" % [IMAGE_DIR, set_id, card_id]
	if not _force and FileAccess.file_exists(path):
		_images_skipped += 1
		return

	var response := await _request("%s/%s.png" % [base_url, _quality])
	if not response["ok"]:
		_failures.append("image %s: %s" % [card_id, response["error"]])
		return

	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_failures.append("image %s: cannot write %s" % [card_id, path])
		return
	file.store_buffer(response["body"] as PackedByteArray)
	file.close()
	_images_downloaded += 1
	await create_timer(REQUEST_DELAY_SEC).timeout


func _get_json_object(url: String) -> Dictionary:
	var response := await _request(url)
	if not response["ok"]:
		printerr("  %s -> %s" % [url, response["error"]])
		return {}
	var body := response["body"] as PackedByteArray
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not parsed is Dictionary:
		printerr("  %s -> response is not a JSON object" % url)
		return {}
	return parsed as Dictionary


## Returns {"ok": true, "body": PackedByteArray} or {"ok": false, "error": String}.
func _request(url: String) -> Dictionary:
	var last_error := ""
	for attempt in MAX_ATTEMPTS:
		if attempt > 0:
			await create_timer(RETRY_DELAY_SEC * attempt).timeout

		var error := _http.request(url, PackedStringArray(HEADERS))
		if error != OK:
			last_error = "request error %d" % error
			continue

		var response: Array = await _http.request_completed
		var result := response[0] as int
		var code := response[1] as int
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			return {"ok": true, "body": response[3] as PackedByteArray}
		if result == HTTPRequest.RESULT_SUCCESS and code == 404:
			return {"ok": false, "error": "HTTP 404"}
		last_error = "HTTP %d" % code if result == HTTPRequest.RESULT_SUCCESS else "network result %d" % result

	return {"ok": false, "error": last_error}


func _load_existing_cards(path: String) -> Dictionary:
	var by_id := {}
	if not FileAccess.file_exists(path):
		return by_id
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return by_id
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return by_id
	for card_value: Variant in (parsed as Dictionary).get("cards", []) as Array:
		var card := card_value as Dictionary
		by_id[str(card.get("id", ""))] = card
	return by_id


func _write_json(path: String, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t") + "\n")
	file.close()
	return true


func _ensure_image_gitignore() -> void:
	var path := IMAGE_DIR + "/.gitignore"
	if FileAccess.file_exists(path):
		return
	DirAccess.make_dir_recursive_absolute(IMAGE_DIR)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string("# Card art is downloaded by tools/import_tcgdex.gd and is not committed.\n*\n!.gitignore\n")
	file.close()


func _by_local_id(a: Dictionary, b: Dictionary) -> bool:
	var a_id := str(a.get("localId", ""))
	var b_id := str(b.get("localId", ""))
	if a_id.is_valid_int() and b_id.is_valid_int():
		return a_id.to_int() < b_id.to_int()
	return a_id.naturalnocasecmp_to(b_id) < 0
