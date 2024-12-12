class_name FreeCell
extends Pile

var freecell_game: FreecellGame

func _card_can_be_added(_cards: Array) -> bool:
	if _cards.size() != 1:
		return false
	var _card = _cards[0]
	var playing_card = _card as PlayingCard
	if playing_card == null:
		return false

	if !is_empty():
		return false

	return true

func is_empty() -> bool:
	return _held_cards.is_empty()


func get_string() -> String:
	var card_info := ""
	if !_held_cards.is_empty():
		var card = _held_cards[0]
		card_info = card.get_string()
	return "Freecell: %d, Top Card: %s" % [unique_id, card_info]


func move_cards(cards: Array):
	super.move_cards(cards)
	freecell_game.update_all_tableaus_cards_can_be_interactwith()
