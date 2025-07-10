@tool
class_name CardManager
extends Control


const CARD_ACCEPT_TYPE = "card"


## size of the card
@export var card_size := Vector2(150, 210)
## card factory scene
@export var card_factory_scene: PackedScene
## debug mode
@export var debug_mode := false


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
	card_container.debug_mode = debug_mode


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
			var index = card_container.get_partition_index()
			card_container.move_cards(cards, index)
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
