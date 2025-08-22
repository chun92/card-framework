## Abstract base class for all card containers in the card framework.
##
## CardContainer provides the foundational functionality for managing collections of cards,
## including drag-and-drop operations, position management, and container interactions.
## All specialized containers (Hand, Pile, etc.) extend this class.
##
## Key Features:
## - Card collection management with position tracking
## - Drag-and-drop integration with DropZone system
## - History tracking for undo/redo operations
## - Extensible layout system through virtual methods
## - Visual debugging support for development
##
## Virtual Methods to Override:
## - _card_can_be_added(): Define container-specific rules
## - _update_target_positions(): Implement container layout logic
## - on_card_move_done(): Handle post-movement processing
##
## Usage:
## [codeblock]
## class_name MyContainer
## extends CardContainer
##
## func _card_can_be_added(cards: Array) -> bool:
##     return cards.size() == 1  # Only allow single cards
## [/codeblock]
class_name CardContainer
extends Control

# Static counter for unique container identification
static var next_id: int = 0


@export_group("drop_zone")
## Enables or disables the drop zone functionality.
@export var enable_drop_zone := true
@export_subgroup("Sensor")
## The size of the sensor. If not set, it will follow the size of the card.
@export var sensor_size: Vector2
## The position of the sensor.
@export var sensor_position: Vector2
## The texture used for the sensor.
@export var sensor_texture: Texture
## Determines whether the sensor is visible or not.
## Since the sensor can move following the status, please use it for debugging.
@export var sensor_visibility := false


# Container identification and management
var unique_id: int
var drop_zone_scene = preload("drop_zone.tscn")
var drop_zone: DropZone = null

# Card collection and state
var _held_cards: Array[Card] = []
var _holding_cards: Array[Card] = []

# Scene references
var cards_node: Control
var card_manager: CardManager
var debug_mode := false


func _init() -> void:
	unique_id = next_id
	next_id += 1


func _ready() -> void:
	# Check if 'Cards' node already exists
	if has_node("Cards"):
		cards_node = $Cards
	else:
		cards_node = Control.new()
		cards_node.name = "Cards"
		cards_node.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(cards_node)
	
	var parent = get_parent()
	if parent is CardManager:
		card_manager = parent
	else:
		push_error("CardContainer should be under the CardManager")
		return
		
	card_manager._add_card_container(unique_id, self)
	
	if enable_drop_zone:
		drop_zone = drop_zone_scene.instantiate()
		add_child(drop_zone)
		drop_zone.init(self, [CardManager.CARD_ACCEPT_TYPE])
		# If sensor_size is not set, they will follow the card size.
		if sensor_size == Vector2(0, 0):
			sensor_size = card_manager.card_size
		drop_zone.set_sensor(sensor_size, sensor_position, sensor_texture, sensor_visibility)
		if debug_mode:
			drop_zone.sensor_outline.visible = true
		else:
			drop_zone.sensor_outline.visible = false


func _exit_tree() -> void:
	if card_manager != null:
		card_manager._delete_card_container(unique_id)


## Adds a card to this container at the specified index.
## @param card: The card to add
## @param index: Position to insert (-1 for end)
func add_card(card: Card, index: int = -1) -> void:
	if index == -1:
		_assign_card_to_container(card)
	else:
		_insert_card_to_container(card, index)
	_move_object(card, cards_node, index)


## Removes a card from this container.
## @param card: The card to remove
## @returns: True if card was removed, false if not found
func remove_card(card: Card) -> bool:
	var index = _held_cards.find(card)
	if index != -1:
		_held_cards.remove_at(index)
	else:
		return false
	update_card_ui()
	return true

## Returns the number of contained cards
func get_card_count() -> int:
	return _held_cards.size()

## Checks if this container contains the specified card.
func has_card(card: Card) -> bool:
	return _held_cards.has(card)


## Removes all cards from this container.
func clear_cards() -> void:
	for card in _held_cards:
		_remove_object(card)
	_held_cards.clear()
	update_card_ui()


## Checks if the specified cards can be dropped into this container.
## Override _card_can_be_added() in subclasses for custom rules.
func check_card_can_be_dropped(cards: Array) -> bool:
	if not enable_drop_zone:
		return false

	if drop_zone == null:
		return false

	if drop_zone.accept_types.has(CardManager.CARD_ACCEPT_TYPE) == false:
		return false
		
	if not drop_zone.check_mouse_is_in_drop_zone():
		return false
		
	return _card_can_be_added(cards)


func get_partition_index() -> int:
	var vertical_index = drop_zone.get_vertical_layers()
	if vertical_index != -1:
		return vertical_index
	var horizontal_index = drop_zone.get_horizontal_layers()
	if horizontal_index != -1:
		return horizontal_index
	return -1


## Shuffles the cards in this container using Fisher-Yates algorithm.
func shuffle() -> void:
	_fisher_yates_shuffle(_held_cards)
	for i in range(_held_cards.size()):
		var card = _held_cards[i]
		cards_node.move_child(card, i)
	update_card_ui()


## Moves cards to this container with optional history tracking.
## @param cards: Array of cards to move
## @param index: Target position (-1 for end)
## @param with_history: Whether to record for undo
## @returns: True if move was successful
func move_cards(cards: Array, index: int = -1, with_history: bool = true) -> bool:
	if not _card_can_be_added(cards):
		return false
	# XXX: If the card is already in the container, we don't add it into the history.
	if not cards.all(func(card): return _held_cards.has(card)) and with_history:
		card_manager._add_history(self, cards)
	_move_cards(cards, index)
	return true


## Restores cards to their original positions with index precision.
## @param cards: Cards to restore
## @param from_indices: Original indices for precise positioning
func undo(cards: Array, from_indices: Array = []) -> void:
	# Validate input parameters
	if not from_indices.is_empty() and cards.size() != from_indices.size():
		push_error("Mismatched cards and indices arrays in undo operation!")
		# Fallback to basic undo
		_move_cards(cards)
		return
	
	# Fallback: add to end if no index info available
	if from_indices.is_empty():
		_move_cards(cards)
		return
	
	# Validate all indices are valid
	for i in range(from_indices.size()):
		if from_indices[i] < 0:
			push_error("Invalid index found during undo: %d" % from_indices[i])
			# Fallback to basic undo
			_move_cards(cards)
			return
	
	# Check if indices are consecutive (bulk move scenario)
	var sorted_indices = from_indices.duplicate()
	sorted_indices.sort()
	var is_consecutive = true
	for i in range(1, sorted_indices.size()):
		if sorted_indices[i] != sorted_indices[i-1] + 1:
			is_consecutive = false
			break
	
	if is_consecutive and sorted_indices.size() > 1:
		# Bulk consecutive restore: maintain original relative order
		var lowest_index = sorted_indices[0]
		
		# Sort cards by their original indices to maintain proper order
		var card_index_pairs = []
		for i in range(cards.size()):
			card_index_pairs.append({"card": cards[i], "index": from_indices[i]})
		
		# Sort by index ascending to maintain original order
		card_index_pairs.sort_custom(func(a, b): return a.index < b.index)
		
		# Insert all cards starting from the lowest index
		for i in range(card_index_pairs.size()):
			var target_index = min(lowest_index + i, _held_cards.size())
			_move_cards([card_index_pairs[i].card], target_index)
	else:
		# Non-consecutive indices: restore individually (original logic)
		var card_index_pairs = []
		for i in range(cards.size()):
			card_index_pairs.append({"card": cards[i], "index": from_indices[i], "original_order": i})
		
		# Sort by index descending, then by original order ascending for stable sorting
		card_index_pairs.sort_custom(func(a, b): 
			if a.index == b.index:
				return a.original_order < b.original_order
			return a.index > b.index
		)
		
		# Restore each card to its original index
		for pair in card_index_pairs:
			var target_index = min(pair.index, _held_cards.size())  # Clamp to valid range
			_move_cards([pair.card], target_index)


func hold_card(card: Card) -> void:
	if _held_cards.has(card):
		_holding_cards.append(card)


func release_holding_cards():
	if _holding_cards.is_empty():
		return
	for card in _holding_cards:
		# Transition from HOLDING to IDLE state
		card.change_state(DraggableObject.DraggableState.IDLE)
	var copied_holding_cards = _holding_cards.duplicate()
	if card_manager != null:
		card_manager._on_drag_dropped(copied_holding_cards)
	_holding_cards.clear()


func get_string() -> String:
	return "card_container: %d" % unique_id


func on_card_move_done(_card: Card):
	pass


func on_card_pressed(_card: Card):
	pass

func _assign_card_to_container(card: Card) -> void:
	if card.card_container != self:
		card.card_container = self
	if not _held_cards.has(card):
		_held_cards.append(card)
	update_card_ui()


func _insert_card_to_container(card: Card, index: int) -> void:
	if card.card_container != self:
		card.card_container = self
	if not _held_cards.has(card):
		if index < 0:
			index = 0
		elif index > _held_cards.size():
			index = _held_cards.size()
		_held_cards.insert(index, card)
	update_card_ui()	


func _move_to_card_container(_card: Card, index: int = -1) -> void:
	if _card.card_container != null:
		_card.card_container.remove_card(_card)
	add_card(_card, index)


func _fisher_yates_shuffle(array: Array) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp


func _move_cards(cards: Array, index: int = -1) -> void:
	var cur_index = index
	for i in range(cards.size() - 1, -1, -1):
		var card = cards[i]
		if cur_index == -1:
			_move_to_card_container(card)
		else:
			_move_to_card_container(card, cur_index)
			cur_index += 1


func _card_can_be_added(_cards: Array) -> bool:
	return true


## Updates the visual positions of all cards in this container.
## Call this after modifying card positions or container properties.
func update_card_ui() -> void:
	_update_target_z_index()
	_update_target_positions()


func _update_target_z_index() -> void:
	pass


func _update_target_positions() -> void:
	pass


func _move_object(target: Node, to: Node, index: int = -1) -> void:
	if target.get_parent() == to:
		# If already the same parent, just change the order with move_child
		if index != -1:
			to.move_child(target, index)
		else:
			# If index is -1, move to the last position
			to.move_child(target, to.get_child_count() - 1)
		return

	var global_pos = target.global_position
	if target.get_parent() != null:
		target.get_parent().remove_child(target)
	if index != -1:
		to.add_child(target)
		to.move_child(target, index)
	else:
		to.add_child(target)
	target.global_position = global_pos


func _remove_object(target: Node) -> void:
	var parent = target.get_parent()
	if parent != null:
		parent.remove_child(target)
	target.queue_free()
