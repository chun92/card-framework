@tool
## Central orchestrator for the card framework system.
##
## CardManager coordinates all card-related operations including drag-and-drop,
## history management, and container registration. It serves as the root node
## for card game scenes and manages the lifecycle of cards and containers.
##
## Key Responsibilities:
## - Card factory management and initialization
## - Container registration and coordination
## - Drag-and-drop event handling and routing
## - History tracking for undo/redo operations
## - Debug mode and visual debugging support
##
## Setup Requirements:
## - Must be the parent of all CardContainer instances
## - Requires card_factory_scene to be assigned in inspector
## - Configure card_size to match your card assets
##
## Usage:
## [codeblock]
## # In scene setup
## CardManager (root)
## ├── Hand (CardContainer)
## ├── Foundation (CardContainer)
## └── Deck (CardContainer)
## [/codeblock]
class_name CardManager
extends Control

# Constants
const CARD_ACCEPT_TYPE = "card"


## Default size for all cards in the game
@export var card_size := CardFrameworkSettings.LAYOUT_DEFAULT_CARD_SIZE
## Scene containing the card factory implementation
@export var card_factory_scene: PackedScene
## Enables visual debugging for drop zones and interactions
@export var debug_mode := false


# Core system components
var card_factory: CardFactory
var card_container_dict: Dictionary = {}
var history: Array[HistoryElement] = []


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


## Undoes the last card movement operation.
## Restores cards to their previous positions using stored history.
func undo() -> void:
	if history.is_empty():
		return
	
	var last = history.pop_back()
	if last.from != null:
		last.from.undo(last.cards, last.from_indices)


## Clears all history entries, preventing further undo operations.
func reset_history() -> void:
	history.clear()
	

func _add_card_container(id: int, card_container: CardContainer) -> void:
	card_container_dict[id] = card_container
	card_container.debug_mode = debug_mode


func _delete_card_container(id: int) -> void:
	card_container_dict.erase(id)


# Handles dropped cards by finding suitable container
func _on_drag_dropped(cards: Array) -> void:
	if cards.is_empty():
		return
	
	# Store original mouse_filter states and temporarily disable input during drop processing
	var original_mouse_filters = {}
	for card in cards:
		original_mouse_filters[card] = card.mouse_filter
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	# Find first container that accepts the cards
	for key in card_container_dict.keys():
		var card_container = card_container_dict[key]
		var result = card_container.check_card_can_be_dropped(cards)
		if result:
			var index = card_container.get_partition_index()
			# Restore mouse_filter before move_cards (DraggableObject will manage it from here)
			for card in cards:
				card.mouse_filter = original_mouse_filters[card]
			card_container.move_cards(cards, index)
			return
	
	for card in cards:
		# Restore mouse_filter before return_card (DraggableObject will manage it from here)
		card.mouse_filter = original_mouse_filters[card]
		card.return_card()


func _add_history(to: CardContainer, cards: Array) -> void:
	var from = null
	var from_indices = []
	
	# Record indices FIRST, before any movement operations
	for i in range(cards.size()):
		var c = cards[i]
		var current = c.card_container
		if i == 0:
			from = current
		else:
			if from != current:
				push_error("All cards must be from the same container!")
				return
		
		# Record index immediately to avoid race conditions
		if from != null:
			var original_index = from._held_cards.find(c)
			if original_index == -1:
				push_error("Card not found in source container during history recording!")
				return
			from_indices.append(original_index)
	
	var history_element = HistoryElement.new()
	history_element.from = from
	history_element.to = to
	history_element.cards = cards
	history_element.from_indices = from_indices
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
