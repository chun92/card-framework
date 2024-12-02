class_name Tableau
extends Pile

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
