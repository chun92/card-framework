class_name CardFactory
extends Node

## card image asset directory
@export
var card_asset_dir: String

## card information json directory
@export
var card_info_dir: String

@export
var back_image: Texture2D

var card_scene = preload("card.tscn")


func create_card(card_name: String, target: Node) -> Card:
	var card_info = _load_card_info(card_name)
	if card_info == null:
		push_error("Card info not found for card: %s" % card_name)
		return null

	var front_image_path = card_asset_dir + "/" + card_info.front_image
	var front_image = _load_image(front_image_path)
	if front_image == null:
		push_error("Card image not found: %s" % front_image_path)
		return null

	var card = _create_card_node(card_info.name, front_image, target)
	return card


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
	if !FileAccess.file_exists(image_path):
		return null
		
	var image = Image.load_from_file(image_path)
	var texture = ImageTexture.create_from_image(image)
	return texture

func _create_card_node(card_name: String, front_image: Texture2D, target: Node) -> Card:
	if not target.has_node("Cards") or not target.has_method("add_card"):
		return null
	
	var card = card_scene.instantiate()
	var cards_node = target.get_node("Cards")
	cards_node.add_child(card)
	target.add_card(card)
	card.card_name = card_name
	card.set_faces(front_image, back_image)

	return card
