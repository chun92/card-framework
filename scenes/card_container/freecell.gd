class_name FreeCell
extends Pile

func card_can_be_added(_card: Card) -> bool:
	var playing_card = _card as PlayingCard
	if playing_card == null:
		return false

	if !is_empty():
		return false

	return true

func is_empty() -> bool:
	return _held_cards.is_empty()
