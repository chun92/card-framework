@tool
class_name JsonCardFactory
extends CardFactory
## Loads cards from JSON files in a specified directory and makes Card instances.
##
## This is an example card factory importing from JSON files
## and makes cards sharing the same backside texture.
## Card data is loaded from [member card_info_dir] and
## their frontside images from [member card_asset_dir].
##
## You may extend it further or make a copy to load from another file type.


## a base card scene to instantiate.
@export var default_card_scene: PackedScene

## card image asset directory
@export var card_asset_dir: String

## card information json directory
@export var card_info_dir: String

## common back face image of cards
@export var back_image: Texture2D


func _ready() -> void:
	if default_card_scene == null:
		push_error("default_card_scene is not assigned!")
		return
		
	var temp_instance = default_card_scene.instantiate()
	if not (temp_instance is Card):
		push_error("Invalid node type! default_card_scene must reference a Card.")
		default_card_scene = null
	temp_instance.queue_free()

## [param target]: The CardContainer where the card will be added.[br]
## Returns the created Card instance.[br]
## [br]
## Gets card data from [member preloaded_cards] if they were preloaded,
## otherwise loads and caches data there for future use.
func create_card(card_name: String, target: CardContainer) -> Card:
	# check card info is cached
	if preloaded_cards.has(card_name):
		var card_info = preloaded_cards[card_name]["info"]
		var front_image = preloaded_cards[card_name]["texture"]
		return _create_card_node(card_info.name, front_image, target, card_info)
	else: 
		# remove all this if cards not preloaded shouldn't try loading in real time
		var card_data = load_card_full_data(card_name)
		if card_data == null: 
			return null
		# add to cache as we know the card isn't in there
		preloaded_cards[card_name] = card_data
		var card_info = preloaded_cards[card_name]["info"]
		var front_image = preloaded_cards[card_name]["texture"]
		return _create_card_node(card_info.name, front_image, target, card_info)


## Preloads card data into the [member preloaded_cards] dictionary.
## This function should be called to initialize card data before creating cards.
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
		var card_data = load_card_full_data(card_name)
		if card_data == null:
			continue

		preloaded_cards[card_name] = card_data
		print("Preloaded card data:", preloaded_cards[card_name])
		
		file_name = dir.get_next()


## Returns a Dictionary with all the data this factory needs to build 
## a Card instance, or null if an error ocurred.[br]
## The format of the data itself is arbitrary and you should change it 
## to better fit your needs.
func load_card_full_data(card_name):
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
	
	return {
		"info": card_info,
		"texture": front_image
	}


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
