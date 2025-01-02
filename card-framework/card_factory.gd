@tool
class_name CardFactory
extends Node

## a base card scene to instantiate.
@export var default_card_scene: PackedScene
var preloaded_cards = {}
var card_asset_dir: String
var card_info_dir: String
var card_size: Vector2
var back_image: Texture2D


func _ready() -> void:
	if default_card_scene == null:
		push_error("default_card_scene is not assigned!")
		return
		
	var temp_instance = default_card_scene.instantiate()
	if not (temp_instance is Card):
		push_error("Invalid node type! default_card_scene must reference a Card.")
		default_card_scene = null
	temp_instance.queue_free()


func create_card(card_name: String, target: CardContainer) -> Card:
	# check card info is cached
	if preloaded_cards.has(card_name):
		var card_info = preloaded_cards[card_name]["info"]
		var front_image = preloaded_cards[card_name]["texture"]
		return _create_card_node(card_info.name, front_image, target, card_info)
	else:
		var card_info = _load_card_info(card_name)
		if card_info == null or card_info == {}:
			push_error("Card info not found for card: %s" % card_name)
			return null

		if not card_info.has("front_image"):
			push_error("Card info does not contain 'front_image' key for card: %s" % card_name)
			return null
		var front_image_path = card_asset_dir + "/" + card_info["front_image"]
		var front_image = _load_image(front_image_path)
		if front_image == null:
			push_error("Card image not found: %s" % front_image_path)
			return null

		return _create_card_node(card_info.name, front_image, target, card_info)


func preload_card_data() -> void:
	var dir = DirAccess.open(card_info_dir)
	if dir == null:
		push_error("Failed to open directory: %s" % card_info_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !file_name.ends_with(".json"):
			file_name = dir.get_next()
			continue

		var card_name = file_name.get_basename()
		var card_info = _load_card_info(card_name)
		if card_info == null:
			push_error("Failed to load card info for %s" % card_name)
			continue

		var front_image_path = card_asset_dir + "/" + card_info.get("front_image", "")
		var front_image_texture = _load_image(front_image_path)
		if front_image_texture == null:
			push_error("Failed to load card image: %s" % front_image_path)
			continue

		preloaded_cards[card_name] = {
			"info": card_info,
			"texture": front_image_texture
		}
		print("Preloaded card data:", preloaded_cards[card_name])
		
		file_name = dir.get_next()


func _load_card_info(card_name: String) -> Dictionary:
	var json_path = card_info_dir + "/" + card_name + ".json"
	if !FileAccess.file_exists(json_path):
		return {}

	var file = FileAccess.open(json_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Failed to parse JSON: %s" % json_path)
		return {}

	return json.data


func _load_image(image_path: String) -> Texture2D:
	var texture = load(image_path) as Texture2D
	if texture == null:
		push_error("Failed to load image resource: %s" % image_path)
		return null
	return texture


func _create_card_node(card_name: String, front_image: Texture2D, target: CardContainer, card_info: Dictionary) -> Card:
	var card = _generate_card(card_info)
	
	if !target._card_can_be_added([card]):
		print("Card cannot be added: %s" % card_name)
		card.queue_free()
		return null
	
	card.card_info = card_info
	card.card_size = card_size
	var cards_node = target.get_node("Cards")
	cards_node.add_child(card)
	target.add_card(card)
	card.card_name = card_name
	card.set_faces(front_image, back_image)

	return card


func _generate_card(_card_info: Dictionary) -> Card:
	if default_card_scene == null:
		push_error("default_card_scene is not assigned!")
		return null
	return default_card_scene.instantiate()
