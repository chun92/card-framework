class_name PlayingCard
extends Card


enum Suit {SPADE = 1, HEART = 2, DIAMOND = 3, CLUB = 4, NONE = 0}
enum Number {_2 = 2, _3 = 3, _4 = 4, _5 = 5, _6 = 6, _7 = 7, _8 = 8, _9 = 9, _10 = 10, _J = 11, _Q = 12, _K = 13, _A = 1, _OTHER = 0}
enum CardColor {BLACK = 1, RED = 2, NONE = 0}


var suit: Suit :
	get():
		return _get_suit_from_string(card_info["suit"])
var number: Number :
	get():
		return _get_number_from_string(card_info["value"])
var card_color: CardColor :
	get():
		match suit:
			Suit.SPADE:
				return CardColor.BLACK
			Suit.HEART:
				return CardColor.RED
			Suit.DIAMOND:
				return CardColor.RED
			Suit.CLUB:
				return CardColor.BLACK
			_:
				return CardColor.NONE
var is_stop_control := false


static func get_suit_as_string(_suit: Suit) -> String:
	var suit_str: String
	match _suit:
		Suit.SPADE:
			suit_str = "spade"
		Suit.HEART:
			suit_str = "heart"
		Suit.DIAMOND:
			suit_str = "diamond"
		Suit.CLUB:
			suit_str = "club"
		_:
			suit_str = "none"
	return suit_str


static func get_number_as_string(_number: Number) -> String:
	var number_str: String
	match _number:
		PlayingCard.Number._A:
			number_str = "A"
		PlayingCard.Number._2:
			number_str = "2"
		PlayingCard.Number._3:
			number_str = "3"
		PlayingCard.Number._4:
			number_str = "4"
		PlayingCard.Number._5:
			number_str = "5"
		PlayingCard.Number._6:
			number_str = "6"
		PlayingCard.Number._7:
			number_str = "7"
		PlayingCard.Number._8:
			number_str = "8"
		PlayingCard.Number._9:
			number_str = "9"
		PlayingCard.Number._10:
			number_str = "10"
		PlayingCard.Number._J:
			number_str = "J"
		PlayingCard.Number._Q:
			number_str = "Q"
		PlayingCard.Number._K:
			number_str = "K"
		PlayingCard.Number._OTHER:
			number_str = "other"
	return number_str


static func get_card_name(_suit: Suit, _number: Number) -> String:
	var suit_str = get_suit_as_string(_suit)
	var number_str = get_number_as_string(_number)
	return suit_str + "_" + number_str


func is_next_number(target_card: PlayingCard) -> bool:
	var current_number = int(number)
	var target_number = int(target_card.number)
	var next_number = (current_number % 13) + 1
	return next_number == target_number
	

func is_different_color(other: PlayingCard) -> bool:
	return card_color != other.card_color


func _get_suit_from_string(_str: String) -> Suit:
	if _str == "spade":
		return Suit.SPADE
	elif _str == "heart":
		return Suit.HEART
	elif _str == "diamond":
		return Suit.DIAMOND
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


func _on_mouse_enter():
	if is_stop_control:
		return
	super._on_mouse_enter()


func _on_mouse_exit():
	if is_stop_control:
		return
	super._on_mouse_exit()


func _on_gui_input(event: InputEvent):
	if is_stop_control:
		return
	super._on_gui_input(event)
