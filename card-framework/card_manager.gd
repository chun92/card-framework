@tool
class_name CardManager
extends Control

## size of the card
@export var card_size := Vector2(150, 210)
## card image asset directory
@export var card_asset_dir: String
## card information json directory
@export var card_info_dir: String
## common back face image of cards
@export var back_image: Texture2D
## card factory scene
@export var card_factory_scene: PackedScene


var card_factory: CardFactory
var card_container_dict := {}
var history := []


func _init() -> void:
	if Engine.is_editor_hint():
		return
	

func _ready() -> void:
	if not _pre_process_exported_variables():
		return
	
	if Engine.is_editor_hint():
		return
	
	card_factory.card_size = card_size
	card_factory.card_asset_dir = card_asset_dir
	card_factory.card_info_dir = card_info_dir
	card_factory.back_image = back_image
	card_factory.preload_card_data()


func undo() -> void:
	if history.is_empty():
		return
	
	var last = history.pop_back()
	if last.from != null:
		last.from.undo(last.cards)


func reset_history() -> void:
	history.clear()
	

func _add_card_container(id: int, card_container: CardContainer):
	card_container_dict[id] = card_container


func _delete_card_container(id: int):
	card_container_dict.erase(id)


func _on_drag_dropped(cards: Array) -> void:
	if cards.is_empty():
		return
	
	for card in cards:
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	for key in card_container_dict.keys():
		var card_container = card_container_dict[key]
		var result = card_container.check_card_can_be_dropped(cards)
		if result:
			card_container.move_cards(cards)
			return
	
	for card in cards:
		card.return_card()


func _add_history(to: CardContainer, cards: Array) -> void:
	var from = null
	
	for i in range(cards.size()):
		var c = cards[i]
		var current = c.card_container
		if i == 0:
			from = current
		else:
			if from != current:
				push_error("All cards must be from the same container!")
				return
	
	var history_element = HistoryElement.new()
	history_element.from = from
	history_element.to = to
	history_element.cards = cards
	history.append(history_element)


func _is_valid_directory(path: String) -> bool:
	var dir = DirAccess.open(path)
	return dir != null


func _pre_process_exported_variables() -> bool:
	if not _is_valid_directory(card_asset_dir):
		push_error("CardManager has invalid card_asset_dir")
		return false
		
	if not _is_valid_directory(card_info_dir):
		push_error("CardManager has invalid card_info_dir")
		return false
		
	if back_image == null:
		push_error("CardManager has no backface image assigned")
		
	if card_factory_scene == null:
		push_error("CardFactory is not assigned! Please set it in the CardManager Inspector.")
		return false
	
	var factory_instance = card_factory_scene.instantiate() as CardFactory
	if factory_instance == null:
		push_error("Failed to create an instance of CardFactory! CardManager imported an incorrect card factory scene.")
		return false
	
	add_child(factory_instance)
	card_factory = factory_instance
	return true
