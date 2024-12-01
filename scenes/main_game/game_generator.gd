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

func show(cards):
	var l = []
	var ranks = "A23456789TJQK"
	var suits = "CDHS"
	for c in cards:
		var rank = ranks[c / 4]
		var suit = suits[c % 4]
		l.append(rank + suit)
	for i in range(0, l.size(), 8):
		var line = " ".join(l.slice(i, i + 8))
		print(line)

func _ready():
	# XXX: Test codes
	var game_seed = 94717719
	print("Hand %d" % game_seed)
	var deck = deal(game_seed)
	show(deck)
