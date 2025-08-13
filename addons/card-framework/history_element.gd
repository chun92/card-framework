class_name HistoryElement
extends Object

# History element that tracks card movements with precise index information
var from: CardContainer
var to: CardContainer
var cards: Array
var from_indices: Array  # Original indices of cards in source container


func get_string() -> String:
	var from_str = from.get_string() if from != null else "null"
	var to_str = to.get_string() if to != null else "null"
	var card_strings = []
	for c in cards:
		card_strings.append(c.get_string())

	var cards_str = ""
	for i in range(card_strings.size()):
		cards_str += card_strings[i]
		if i < card_strings.size() - 1:
			cards_str += ", "
	
	var indices_str = str(from_indices) if not from_indices.is_empty() else "[]"
	return "from: [%s], to: [%s], cards: [%s], indices: %s" % [from_str, to_str, cards_str, indices_str]
