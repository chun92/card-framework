class_name Tableau
extends Pile


## Maximum length (in pixels) that the card stack can occupy. 
## If not set or set to 0, the stack length is unlimited.
@export var max_stack_length: int


var freecell_game: FreecellGame
var is_initializing := false


func _ready():
	super._ready()
	restrict_to_top_card = false


func is_empty() -> bool:
	return _held_cards.is_empty()


func on_card_pressed(card: Card):
	freecell_game.hold_multiple_cards(card, self)


func get_string() -> String:
	var card_info := ""
	var card = get_top_card()
	if card != null:
		card_info = card.get_string()
	var held_card_size = _held_cards.size()
	return "Tableau: %d, Top Card: %s, Size: %d" % [unique_id, card_info, held_card_size]


func move_cards(cards: Array, with_history: bool = true) -> bool:
	var result = super.move_cards(cards, with_history)
	if result:
		freecell_game.move_count += 1
		freecell_game.update_all_tableaus_cards_can_be_interactwith(true)
	return result


func init_move_cards(cards: Array, with_history: bool = true) -> void:
	super.move_cards(cards, with_history)
	freecell_game.update_all_tableaus_cards_can_be_interactwith(true)


func undo(cards: Array) -> void:
	super.undo(cards)
	freecell_game.undo_count += 1
	freecell_game.update_all_tableaus_cards_can_be_interactwith(false)


func get_top_card() -> PlayingCard:
	if _held_cards.size() == 0:
		return null
	return _held_cards.back() as PlayingCard


func _card_can_be_added(_cards: Array) -> bool:
	if _cards.size() > freecell_game.maximum_number_of_super_move(self):
		return false
	if _cards.is_empty():
		return false

	var card = _cards[-1]
	var target_card = card as PlayingCard
	if target_card == null:
		return false
		
	if is_initializing:
		return true
		
	if is_empty():
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

	var offset = Vector2()
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


func _move_cards(cards: Array) -> void:
	for i in range(cards.size() - 1, -1, -1):
		var card = cards[i]
		_move_to_card_container(card)
