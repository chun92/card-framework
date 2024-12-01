class_name FreeCell
extends Pile

func card_can_be_added(_card: Card) -> bool:
	var playing_card = _card as PlayingCard
	if playing_card == null:
		return false

	if _held_cards.size() >= 1:
		return false

	return true
