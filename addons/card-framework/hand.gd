class_name Hand
extends CardContainer

@export_group("hand_meta_info")
## maximum number of cards that can be held.
@export var max_hand_size := 10
## maximum spread of the hand.
@export var max_hand_spread := 700
## whether the card is face up.
@export var card_face_up := true
## distance the card hovers when interacted with.
@export var card_hover_distance := 30

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


func _update_target_z_index():
	for i in range(_held_cards.size()):
		var card = _held_cards[i]
		card.stored_z_index = i


func _update_target_positions():
	var x_min: float
	var x_max: float
	var y_min: float
	var y_max: float
	var card_size = card_manager.card_size
	var _w = card_size.x
	var _h = card_size.y

	vertical_partitions_from_outside.clear()
	
	for i in range(_held_cards.size()):
		var card = _held_cards[i]
		var hand_ratio = 0.5
		if _held_cards.size() > 1:
			hand_ratio = float(i) / float(_held_cards.size() - 1)
		var target_pos = global_position
		@warning_ignore("integer_division")
		var card_spacing = max_hand_spread / (_held_cards.size() + 1)
		target_pos.x += (i + 1) * card_spacing - max_hand_spread / 2.0
		if hand_vertical_curve:
			target_pos.y -= hand_vertical_curve.sample(hand_ratio)
		var target_rotation = 0
		if hand_rotation_curve:
			target_rotation = deg_to_rad(hand_rotation_curve.sample(hand_ratio))
		
		var _x = target_pos.x
		var _y = target_pos.y
			
		var _t1 = atan2(_h, _w) + target_rotation
		var _t2 = atan2(_h, -_w) + target_rotation
		var _t3 = _t1 + PI + target_rotation
		var _t4 = _t2 + PI + target_rotation
		var _c = Vector2(_x + _w / 2, _y + _h / 2)
		var _r = sqrt(pow(_w / 2, 2.0) + pow(_h / 2, 2.0))
		var _p1 = Vector2(_r * cos(_t1), _r * sin(_t1)) + _c # right bottom
		var _p2 = Vector2(_r * cos(_t2), _r * sin(_t2)) + _c # left bottom
		var _p3 = Vector2(_r * cos(_t3), _r * sin(_t3)) + _c # left top
		var _p4 = Vector2(_r * cos(_t4), _r * sin(_t4)) + _c # right top
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
	if swap_only_on_reorder and cards.size() == 1 and _held_cards.has(cards[0]) and index >= 0 and index < _held_cards.size():
		swap_card(cards[0], index)
		return true

	return super.move_cards(cards, index, with_history)


func swap_card(card: Card, index: int) -> void:
	var current_index = _held_cards.find(card)
	if current_index == index:
		return
	var temp = _held_cards[current_index]
	_held_cards[current_index] = _held_cards[index]
	_held_cards[index] = temp
	update_card_ui()


func hold_card(card: Card) -> void:
	if _held_cards.has(card):
		drop_zone.set_vertical_partitions(vertical_partitions_from_inside)
	super.hold_card(card)
