## A fan-shaped card container that arranges cards in an arc formation.
##
## Hand provides sophisticated card layout using mathematical curves to create
## natural-looking card arrangements. Cards are positioned in a fan pattern
## with configurable spread, rotation, and vertical displacement.
##
## Key Features:
## - Fan-shaped card arrangement with customizable curves
## - Smooth card reordering with optional swap-only mode  
## - Dynamic drop zone sizing to match hand spread
## - Configurable card limits and hover distances
## - Mathematical positioning using Curve resources
##
## Curve Configuration:
## - hand_rotation_curve: Controls card rotation (linear -X to +X recommended)
## - hand_vertical_curve: Controls vertical offset (3-point ease 0-X-0 recommended)
##
## Usage:
## [codeblock]
## @onready var hand = $Hand
## hand.max_hand_size = 7
## hand.max_hand_spread = 600
## hand.card_face_up = true
## [/codeblock]
class_name Hand
extends CardContainer

@export_group("hand_meta_info")
## maximum number of cards that can be held.
@export var max_hand_size := CardFrameworkSettings.LAYOUT_MAX_HAND_SIZE
## maximum spread of the hand.
@export var max_hand_spread := CardFrameworkSettings.LAYOUT_MAX_HAND_SPREAD
## whether the card is face up.
@export var card_face_up := true
## distance the card hovers when interacted with.
@export var card_hover_distance := CardFrameworkSettings.PHYSICS_CARD_HOVER_DISTANCE

@export_group("hand_shape")
## rotation curve of the hand.
## This works best as a 2-point linear rise from -X to +X.
@export var hand_rotation_curve : Curve
## vertical curve of the hand.
## This works best as a 3-point ease in/out from 0 to X to 0
@export var hand_vertical_curve : Curve

@export_group("drop_zone")
## Determines whether the drop zone size follows the hand size. (requires enable drop zone true)
@export var align_drop_zone_size_with_current_hand_size := true
## If true, only swap the positions of two cards when reordering (a <-> b), otherwise shift the range (default behavior).
@export var swap_only_on_reorder := false


var vertical_partitions_from_outside = []
var vertical_partitions_from_inside = []


func _ready() -> void:
	super._ready()


## Returns a random selection of cards from this hand.
## @param n: Number of cards to select
## @returns: Array of randomly selected cards
func get_random_cards(n: int) -> Array:
	var deck = _held_cards.duplicate()
	deck.shuffle()
	if n > _held_cards.size():
		n = _held_cards.size()
	return deck.slice(0, n)


func _card_can_be_added(_cards: Array) -> bool:
	var is_all_cards_contained = true
	for i in range(_cards.size()):
		var card = _cards[i]
		if !_held_cards.has(card):
			is_all_cards_contained = false
	
	if is_all_cards_contained:
		return true
			
	var card_size = _cards.size()
	return _held_cards.size() + card_size <= max_hand_size


func _update_target_z_index() -> void:
	for i in range(_held_cards.size()):
		var card = _held_cards[i]
		card.stored_z_index = i


## Calculates target positions for all cards using mathematical curves.
## Implements sophisticated fan-shaped arrangement with rotation and vertical displacement.
func _update_target_positions() -> void:
	var x_min: float
	var x_max: float
	var y_min: float
	var y_max: float
	var card_size = card_manager.card_size
	var _w = card_size.x
	var _h = card_size.y

	vertical_partitions_from_outside.clear()
	
	# Calculate position and rotation for each card in the fan arrangement
	for i in range(_held_cards.size()):
		var card = _held_cards[i]
		
		# Calculate normalized position ratio (0.0 to 1.0) for curve sampling
		var hand_ratio = 0.5  # Single card centered
		if _held_cards.size() > 1:
			hand_ratio = float(i) / float(_held_cards.size() - 1)
		
		# Calculate base horizontal position with even spacing
		var target_pos = global_position
		@warning_ignore("integer_division")
		var card_spacing = max_hand_spread / (_held_cards.size() + 1)
		target_pos.x += (i + 1) * card_spacing - max_hand_spread / 2.0
		
		# Apply vertical curve displacement for fan shape
		if hand_vertical_curve:
			target_pos.y -= hand_vertical_curve.sample(hand_ratio)
		
		# Apply rotation curve for realistic card fanning
		var target_rotation = 0
		if hand_rotation_curve:
			target_rotation = deg_to_rad(hand_rotation_curve.sample(hand_ratio))
		
		# Calculate rotated card bounding box for drop zone partitioning
		# This complex math determines the actual screen space occupied by each rotated card
		var _x = target_pos.x
		var _y = target_pos.y
		
		# Calculate angles to card corners after rotation
		var _t1 = atan2(_h, _w) + target_rotation      # bottom-right corner
		var _t2 = atan2(_h, -_w) + target_rotation     # bottom-left corner  
		var _t3 = _t1 + PI + target_rotation           # top-left corner
		var _t4 = _t2 + PI + target_rotation           # top-right corner
		
		# Card center and radius for corner calculation
		var _c = Vector2(_x + _w / 2, _y + _h / 2)     # card center
		var _r = sqrt(pow(_w / 2, 2.0) + pow(_h / 2, 2.0))  # diagonal radius
		
		# Calculate actual corner positions after rotation
		var _p1 = Vector2(_r * cos(_t1), _r * sin(_t1)) + _c # right bottom
		var _p2 = Vector2(_r * cos(_t2), _r * sin(_t2)) + _c # left bottom
		var _p3 = Vector2(_r * cos(_t3), _r * sin(_t3)) + _c # left top
		var _p4 = Vector2(_r * cos(_t4), _r * sin(_t4)) + _c # right top
		
		# Find bounding box of rotated card
		var current_x_min = min(_p1.x, _p2.x, _p3.x, _p4.x)
		var current_x_max = max(_p1.x, _p2.x, _p3.x, _p4.x)
		var current_y_min = min(_p1.y, _p2.y, _p3.y, _p4.y)
		var current_y_max = max(_p1.y, _p2.y, _p3.y, _p4.y)
		var current_x_mid = (current_x_min + current_x_max) / 2
		vertical_partitions_from_outside.append(current_x_mid)
		
		if i == 0:
			x_min = current_x_min
			x_max = current_x_max
			y_min = current_y_min 
			y_max = current_y_max
		else:
			x_min = minf(x_min, current_x_min)
			x_max = maxf(x_max, current_x_max)
			y_min = minf(y_min, current_y_min)
			y_max = maxf(y_max, current_y_max)

		card.move(target_pos, target_rotation)
		card.show_front = card_face_up
		card.can_be_interacted_with = true

	# Calculate midpoints between consecutive values in vertical_partitions_from_outside
	vertical_partitions_from_inside.clear()
	if vertical_partitions_from_outside.size() > 1:
		for j in range(vertical_partitions_from_outside.size() - 1):
			var mid = (vertical_partitions_from_outside[j] + vertical_partitions_from_outside[j + 1]) / 2.0
			vertical_partitions_from_inside.append(mid)
		
	if align_drop_zone_size_with_current_hand_size:
		if _held_cards.size() == 0:
			drop_zone.return_sensor_size()
		else:
			var _size = Vector2(x_max - x_min, y_max - y_min)
			var _position = Vector2(x_min, y_min) - position
			drop_zone.set_sensor_size_flexibly(_size, _position)
		drop_zone.set_vertical_partitions(vertical_partitions_from_outside)


func move_cards(cards: Array, index: int = -1, with_history: bool = true) -> bool:
	# Handle single card reordering within same Hand container
	if cards.size() == 1 and _held_cards.has(cards[0]) and index >= 0 and index < _held_cards.size():
		var current_index = _held_cards.find(cards[0])
		
		# Swap-only mode: exchange two cards directly
		if swap_only_on_reorder:
			swap_card(cards[0], index)
			return true
		
		# Same position optimization
		if current_index == index:
			# Same card, same position - ensure consistent state
			update_card_ui()
			_restore_mouse_interaction(cards)
			return true
		
		# Different position: use efficient internal reordering
		_reorder_card_in_hand(cards[0], current_index, index, with_history)
		_restore_mouse_interaction(cards)
		return true

	# Fall back to parent implementation for other cases
	return super.move_cards(cards, index, with_history)


func swap_card(card: Card, index: int) -> void:
	var current_index = _held_cards.find(card)
	if current_index == index:
		return
	var temp = _held_cards[current_index]
	_held_cards[current_index] = _held_cards[index]
	_held_cards[index] = temp
	update_card_ui()


## Restore mouse interaction for cards after drag & drop completion.
func _restore_mouse_interaction(cards: Array) -> void:
	# Restore mouse interaction for cards after drag & drop completion.
	for card in cards:
		card.mouse_filter = Control.MOUSE_FILTER_STOP


## Efficiently reorder card within Hand without intermediate UI updates.
## Prevents position calculation errors during same-container moves.
func _reorder_card_in_hand(card: Card, from_index: int, to_index: int, with_history: bool) -> void:
	# Efficiently reorder card within Hand without intermediate UI updates.
	# Add to history if needed (before making changes)
	if with_history:
		card_manager._add_history(self, [card])
	
	# Efficient array reordering without intermediate states
	_held_cards.remove_at(from_index)
	_held_cards.insert(to_index, card)
	
	# Single UI update after array change
	update_card_ui()


func hold_card(card: Card) -> void:
	if _held_cards.has(card):
		drop_zone.set_vertical_partitions(vertical_partitions_from_inside)
	super.hold_card(card)
