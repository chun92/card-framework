class_name GameGenerator
extends Node

func random_generator(_seed = 1, count = 1):
	var max_int32 = (1 << 31) - 1
	_seed = _seed & max_int32
	var rnd_numbers = []
	for i in range(count):
		_seed = (_seed * 214013 + 2531011) & max_int32
		rnd_numbers.append(_seed >> 16)
	return rnd_numbers

func deal(_seed):
	var nc = 52
	var cards = []
	for i in range(nc - 1, -1, -1):
		cards.append(i)
	var rnd_numbers = random_generator(_seed, nc)
	for i in range(nc):
		var r = rnd_numbers[i]
		var j = (nc - 1) - r % (nc - i)
		var temp = cards[i]
		cards[i] = cards[j]
		cards[j] = temp
	return cards


func generate_cards(cards) -> Array:
	var results = []
	for c in cards:
		var suit = _get_suit(c)
		var number = _get_number(c)
		var card_name = PlayingCard.get_card_name(suit, number)
		results.append(card_name)
	return results


func print_log(cards):
	var l = []
	var numbers = "A23456789TJQK"
	var suits = "CDHS"
	for c in cards:
		var number = numbers[c / 4]
		var suit = suits[c % 4]
		l.append(number + suit)
	for i in range(0, l.size(), 8):
		var line = " ".join(l.slice(i, i + 8))
		print(line)



func _get_number(card: int) -> PlayingCard.Number:
	var num = card / 4
	match num:
		0: 
			return PlayingCard.Number._A
		1: 
			return PlayingCard.Number._2
		2: 
			return PlayingCard.Number._3
		3: 
			return PlayingCard.Number._4
		4: 
			return PlayingCard.Number._5
		5: 
			return PlayingCard.Number._6
		6: 
			return PlayingCard.Number._7
		7: 
			return PlayingCard.Number._8
		8: 
			return PlayingCard.Number._9
		9: 
			return PlayingCard.Number._10
		10: 
			return PlayingCard.Number._J
		11: 
			return PlayingCard.Number._Q
		12: 
			return PlayingCard.Number._K
		_:
			push_error("Wrong card number within the game generating process")
			return PlayingCard.Number._OTHER


func _get_suit(card: int) -> PlayingCard.Suit:
	var num = card % 4
	match num:
		0: 
			return PlayingCard.Suit.CLUB
		1: 
			return PlayingCard.Suit.DIAMOND
		2: 
			return PlayingCard.Suit.HEART
		3: 
			return PlayingCard.Suit.SPADE
		_: 
			push_error("Wrong card suit within the game generating process")
			return PlayingCard.Suit.NONE


func _ready():
	# XXX: Test codes
	var game_seed = 94717719
	print("Hand %d" % game_seed)
	var deck = deal(game_seed)
	generate_cards(deck)
	print_log(deck)
	
