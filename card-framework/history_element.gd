class_name HistoryElement
extends Object


var from: CardContainer
var to: CardContainer
var cards: Array


func get_string() -> String:
	var from_str = from.get_string()
	var to_str = to.get_string()
	var card_strings = []
	for c in cards:
		card_strings.append(c.get_string())

	var cards_str = ""
	for i in range(card_strings.size()):
		cards_str += card_strings[i]
		if i < card_strings.size() - 1:
			cards_str += ", "

	return "from: [%s], to: [%s], cards: [%s]" % [from_str, to_str, cards_str]
