class_name Foundation
extends Pile

@export var suit:= PlayingCard.Suit.NONE
var freecell_game: FreecellGame

func _card_can_be_added(_cards: Array) -> bool:
	if _cards.size() != 1:
		return false
	var _card = _cards[0]
	var target_card = _card as PlayingCard
	if target_card == null:
		return false
	
	if target_card.suit != suit:
		return false
		
	if _held_cards.is_empty():
		return target_card.number == PlayingCard.Number._A
	var current_top_card = _held_cards.back() as PlayingCard
	if current_top_card.is_next_number(target_card):
		return true
	else:
		return false


func move_cards(cards: Array):
	super.move_cards(cards)
	freecell_game.update_all_tableaus_cards_can_be_interactwith()