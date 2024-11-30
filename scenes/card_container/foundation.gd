class_name Foundation
extends Pile

@export var suit: PlayingCard.Suit

func card_can_be_added(_card: Card) -> bool:
	var target_card = _card as PlayingCard
	if target_card == null:
		return false
		
	if target_card.suit != suit:
		return false
		
	var current_top_card = _held_cards.back() as PlayingCard
	if current_top_card == null:
		return false
		
	if current_top_card.is_next_number(target_card):
		return true
	else:
		return false
