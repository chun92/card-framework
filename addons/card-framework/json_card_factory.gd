@tool
## JSON-based card factory implementation with asset management and caching.
##
## JsonCardFactory extends CardFactory to provide JSON-based card creation with
## sophisticated asset loading, data caching, and error handling. It manages
## card definitions stored as JSON files and automatically loads corresponding
## image assets from specified directories.
##
## Key Features:
## - JSON-based card data definition with flexible schema
## - Automatic asset loading and texture management  
## - Performance-optimized data caching for rapid card creation
## - Comprehensive error handling with detailed logging
## - Directory scanning for bulk card data preloading
## - Configurable asset and data directory paths
##
## File Structure Requirements:
## [codeblock]
## project/
## ├── card_assets/          # card_asset_dir
## │   ├── ace_spades.png
## │   └── king_hearts.png
## ├── card_data/            # card_info_dir  
## │   ├── ace_spades.json   # Matches asset filename
## │   └── king_hearts.json
## [/codeblock]
##
## JSON Schema Example:
## [codeblock]
## {
##   "name": "ace_spades",
##   "front_image": "ace_spades.png", 
##   "suit": "spades",
##   "value": "ace"
## }
## [/codeblock]
class_name JsonCardFactory
extends CardFactory

@export_group("card_scenes")
## Base card scene to instantiate for each card (must inherit from Card class)
@export var default_card_scene: PackedScene

@export_group("asset_paths") 
## Directory path containing card image assets (PNG, JPG, etc.)
@export var card_asset_dir: String
## Directory path containing card information JSON files
@export var card_info_dir: String

@export_group("default_textures")
## Common back face texture used for all cards when face-down
@export var back_image: Texture2D


## Validates configuration and default card scene on initialization.
## Ensures default_card_scene references a valid Card-inherited node.
func _ready() -> void:
	if default_card_scene == null:
		push_error("default_card_scene is not assigned!")
		return
		
	# Validate that default_card_scene produces Card instances
	var temp_instance = default_card_scene.instantiate()
	if not (temp_instance is Card):
		push_error("Invalid node type! default_card_scene must reference a Card.")
		default_card_scene = null
	temp_instance.queue_free()


## Creates a new card instance with JSON data and adds it to the target container.
## Uses cached data if available, otherwise loads from JSON and asset files.
## @param card_name: Identifier matching JSON filename (without .json extension)
## @param target: CardContainer to receive the new card
## @returns: Created Card instance or null if creation failed
func create_card(card_name: String, target: CardContainer) -> Card:
	# Use cached data for optimal performance
	if preloaded_cards.has(card_name):
		var card_info = preloaded_cards[card_name]["info"]
		var front_image = preloaded_cards[card_name]["texture"]
		return _create_card_node(card_info.name, front_image, target, card_info)
	else:
		# Load card data on-demand (slower but supports dynamic loading)
		var card_info = _load_card_info(card_name)
		if card_info == null or card_info == {}:
			push_error("Card info not found for card: %s" % card_name)
			return null

		# Validate required JSON fields
		if not card_info.has("front_image"):
			push_error("Card info does not contain 'front_image' key for card: %s" % card_name)
			return null
			
		# Load corresponding image asset
		var front_image_path = card_asset_dir + "/" + card_info["front_image"]
		var front_image = _load_image(front_image_path)
		if front_image == null:
			push_error("Card image not found: %s" % front_image_path)
			return null

		return _create_card_node(card_info.name, front_image, target, card_info)


## Scans card info directory and preloads all JSON data and textures into cache.
## Significantly improves card creation performance by eliminating file I/O during gameplay.
## Should be called during game initialization or loading screens.
func preload_card_data() -> void:
	var dir = DirAccess.open(card_info_dir)
	if dir == null:
		push_error("Failed to open directory: %s" % card_info_dir)
		return

	# Scan directory for all JSON files
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		# Skip non-JSON files
		if !file_name.ends_with(".json"):
			file_name = dir.get_next()
			continue

		# Extract card name from filename (without .json extension)
		var card_name = file_name.get_basename()
		var card_info = _load_card_info(card_name)
		if card_info == null:
			push_error("Failed to load card info for %s" % card_name)
			continue

		# Load corresponding texture asset
		var front_image_path = card_asset_dir + "/" + card_info.get("front_image", "")
		var front_image_texture = _load_image(front_image_path)
		if front_image_texture == null:
			push_error("Failed to load card image: %s" % front_image_path)
			continue

		# Cache both JSON data and texture for fast access
		preloaded_cards[card_name] = {
			"info": card_info,
			"texture": front_image_texture
		}
		print("Preloaded card data:", preloaded_cards[card_name])
		
		file_name = dir.get_next()


## Loads and parses JSON card data from file system.
## @param card_name: Card identifier (filename without .json extension)
## @returns: Dictionary containing card data or empty dict if loading failed
func _load_card_info(card_name: String) -> Dictionary:
	var json_path = card_info_dir + "/" + card_name + ".json"
	if !FileAccess.file_exists(json_path):
		return {}

	# Read JSON file content
	var file = FileAccess.open(json_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()

	# Parse JSON with error handling
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		push_error("Failed to parse JSON: %s" % json_path)
		return {}

	return json.data


## Loads image texture from file path with error handling.
## @param image_path: Full path to image file
## @returns: Loaded Texture2D or null if loading failed
func _load_image(image_path: String) -> Texture2D:
	var texture = load(image_path) as Texture2D
	if texture == null:
		push_error("Failed to load image resource: %s" % image_path)
		return null
	return texture


## Creates and configures a card node with textures and adds it to target container.
## @param card_name: Card identifier for naming and reference
## @param front_image: Texture for card front face
## @param target: CardContainer to receive the card
## @param card_info: Dictionary of card data from JSON
## @returns: Configured Card instance or null if addition failed
func _create_card_node(card_name: String, front_image: Texture2D, target: CardContainer, card_info: Dictionary) -> Card:
	var card = _generate_card(card_info)
	
	# Validate container can accept this card
	if !target._card_can_be_added([card]):
		print("Card cannot be added: %s" % card_name)
		card.queue_free()
		return null
	
	# Configure card properties
	card.card_info = card_info
	card.card_size = card_size
	
	# Add to scene tree and container
	var cards_node = target.get_node("Cards")
	cards_node.add_child(card)
	target.add_card(card)
	
	# Set card identity and textures
	card.card_name = card_name
	card.set_faces(front_image, back_image)

	return card


## Instantiates a new card from the default card scene.
## @param _card_info: Card data dictionary (reserved for future customization)
## @returns: New Card instance or null if scene is invalid
func _generate_card(_card_info: Dictionary) -> Card:
	if default_card_scene == null:
		push_error("default_card_scene is not assigned!")
		return null
	return default_card_scene.instantiate()
