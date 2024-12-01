class_name PlayingCard
extends Card

enum Suit {SPADE = 1, HEART = 2, DIAMOND = 3, CLUB = 4, NONE = 0}
enum Number {_2 = 2, _3 = 3, _4 = 4, _5 = 5, _6 = 6, _7 = 7, _8 = 8, _9 = 9, _10 = 10, _J = 11, _Q = 12, _K = 13, _A = 1, _OTHER = 0}

var suit: Suit :
	get():
		return _get_suit_from_string(card_info["suit"])

var number: Number :
	get():
		return _get_number_from_string(card_info["value"])


func is_next_number(target_card: PlayingCard) -> bool:
	var current_number = int(number)
	var target_number = int(target_card.number)
	var next_number = (current_number % 13) + 1
	return next_number == target_number


func _get_suit_from_string(_str: String) -> Suit:
	if _str == "spade":
		return Suit.SPADE
	elif _str == "heart":
		return Suit.HEART
	elif _str == "diamond":
		return Suit.HEART
	elif _str == "club":
		return Suit.CLUB
	else:
		return Suit.NONE


func _get_number_from_string(_str: String) -> Number:
	if _str == "2":
		return Number._2
	elif _str == "3":
		return Number._3
	elif _str == "4":
		return Number._4
	elif _str == "5":
		return Number._5
	elif _str == "6":
		return Number._6
	elif _str == "7":
		return Number._7
	elif _str == "8":
		return Number._8
	elif _str == "9":
		return Number._9
	elif _str == "10":
		return Number._10
	elif _str == "J":
		return Number._J
	elif _str == "Q":
		return Number._Q
	elif _str == "K":
		return Number._K
	elif _str == "A":
		return Number._A
	else:
		return Number._OTHER
