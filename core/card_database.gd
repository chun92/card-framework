class_name CardDatabase
extends RefCounted
## Holds raw TCGdex card objects and builds fresh CardData instances from them.

var errors: Array[String] = []
var warnings: Array[String] = []

var _raw_by_id: Dictionary = {}
var _parser := TcgdexParser.new()


## Adds every card of one data/tcgdex/<set>.json document. Cards that fail to parse
## are reported in errors and left out, so make() never returns a half-built card.
func load_set(set_document: Dictionary) -> void:
	for entry: Variant in set_document.get("cards", []) as Array:
		if not entry is Dictionary:
			errors.append("CardDatabase: card entry is not an object")
			continue
		var raw := entry as Dictionary
		var id := str(raw.get("id", ""))
		if _raw_by_id.has(id):
			errors.append("CardDatabase: duplicate card id '%s'" % id)
			continue

		_parser.clear_messages()
		var card := _parser.parse(raw)
		errors.append_array(_parser.errors)
		warnings.append_array(_parser.warnings)
		if card != null:
			_raw_by_id[id] = raw


func card_count() -> int:
	return _raw_by_id.size()


func has_card(id: String) -> bool:
	return _raw_by_id.has(id)


func all_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(_raw_by_id.keys())
	return ids


## Builds a new CardData on every call. Each physical copy is a distinct object.
func make(id: String) -> CardData:
	if not _raw_by_id.has(id):
		push_error("CardDatabase: unknown card id '%s'" % id)
		return null
	_parser.clear_messages()
	return _parser.parse(_raw_by_id[id] as Dictionary)


func build_deck(deck_def: Dictionary) -> Array[CardData]:
	var deck: Array[CardData] = []
	var counts := deck_def.get("cards", {}) as Dictionary
	for id: Variant in counts:
		for _copy in int(counts[id]):
			var card := make(str(id))
			if card != null:
				deck.append(card)
	return deck
