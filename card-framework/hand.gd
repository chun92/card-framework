class_name Hand
extends CardContainer

## hand area size.
@export var hand_area: Vector2

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


func _ready() -> void:
	super._ready()
	size = hand_area


func get_random_cards(n: int) -> Array:
	var deck = _held_cards.duplicate()
	deck.shuffle()
	if n > _held_cards.size():
		n = _held_cards.size()
	return deck.slice(0, n)


func _card_can_be_added(_cards: Array) -> bool:
	var card_size = _cards.size()
	return _held_cards.size() + card_size <= max_hand_size


func _update_target_z_index():
	for i in range(_held_cards.size()):
		var card = _held_cards[i]
		card.stored_z_index = i


func _update_target_positions():
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
		card.move(target_pos, target_rotation)
		card.show_front = card_face_up
		card.can_be_interacted_with = true
