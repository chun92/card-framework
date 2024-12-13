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


func get_string() -> String:
	var card_info := ""
	var card = get_top_card()
	if card != null:
		card_info = card.get_string()
	var suit_str = PlayingCard.get_suit_as_string(suit)
	return "Foundation: %s, Top Card: %s" % [suit_str, card_info]

func _move_cards(cards: Array):
	for i in range(cards.size() - 1, -1, -1):
		var card = cards[i]
		_move_to_card_container(card)

func move_cards(cards: Array, with_history: bool = true):
	super.move_cards(cards, with_history)
	freecell_game.move_count += 1
	freecell_game.update_all_tableaus_cards_can_be_interactwith(true)


func auto_move_cards(cards: Array, with_history: bool = true):
	super.move_cards(cards, with_history)
	freecell_game.update_all_tableaus_cards_can_be_interactwith(true)


func undo(cards: Array):
	super.undo(cards)
	freecell_game.undo_count += 1
	freecell_game.update_all_tableaus_cards_can_be_interactwith(false)


func get_top_card() -> PlayingCard:
	if _held_cards.size() == 0:
		return null
	return _held_cards.back() as PlayingCard
