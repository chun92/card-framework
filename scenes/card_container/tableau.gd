class_name Tableau
extends Pile


##Maximum length (in pixels) that the card stack can occupy. 
#If not set or set to 0, the stack length is unlimited.
@export var max_stack_length: int

func card_can_be_added(_card: Card) -> bool:
	var target_card = _card as PlayingCard
	if target_card == null:
		return false
		
	if _held_cards.is_empty():
		return true
	
	var current_top_card = _held_cards.back() as PlayingCard
	if current_top_card.number == PlayingCard.Number._A:
		return false
		
	if not current_top_card.is_different_color(target_card):
		return false
		
	if target_card.is_next_number(current_top_card):
		return true
		
	return false


func _calculate_offset(index: int) -> Vector2:
	var total_cards_in_stack = _held_cards.size()
	var offset = Vector2()
	var total_display_cards = min(total_cards_in_stack, max_stack_display)
	var total_gaps = total_display_cards - 1

	var adjusted_gap = stack_display_gap
	if total_gaps > 0:
		if max_stack_length != 0:
			adjusted_gap = min(stack_display_gap, max_stack_length / total_gaps)
		else:
			adjusted_gap = stack_display_gap
	else:
		adjusted_gap = 0

	var actual_index = min(index, max_stack_display - 1)
	var offset_value = actual_index * adjusted_gap

	match layout:
		PileDirection.UP:
			offset.y -= offset_value
		PileDirection.DOWN:
			offset.y += offset_value
		PileDirection.RIGHT:
			offset.x += offset_value
		PileDirection.LEFT:
			offset.x -= offset_value

	return offset
