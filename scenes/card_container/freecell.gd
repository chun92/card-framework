class_name FreeCell
extends Pile


var freecell_game: FreecellGame


func is_empty() -> bool:
	return _held_cards.is_empty()


func get_top_card() -> PlayingCard:
	if is_empty():
		return null
	return _held_cards[0] as PlayingCard


func get_string() -> String:
	var card_info := ""
	if not is_empty():
		var card = _held_cards[0]
		card_info = card.get_string()
	return "Freecell: %d, Top Card: %s" % [unique_id, card_info]


func move_cards(cards: Array, with_history: bool = true) -> bool:
	var result = super.move_cards(cards, with_history)
	if result:
		freecell_game.move_count += 1
		freecell_game.update_all_tableaus_cards_can_be_interactwith(true)
	return result


func undo(cards: Array) -> void:
	super.undo(cards)
	freecell_game.undo_count += 1
	freecell_game.update_all_tableaus_cards_can_be_interactwith(false)


func _card_can_be_added(_cards: Array) -> bool:
	if _cards.size() != 1:
		return false
	var _card = _cards[0]
	var playing_card = _card as PlayingCard
	if playing_card == null:
		return false

	if not is_empty():
		return false

	return true


func _move_cards(cards: Array) -> void:
	for i in range(cards.size() - 1, -1, -1):
		var card = cards[i]
		_move_to_card_container(card)