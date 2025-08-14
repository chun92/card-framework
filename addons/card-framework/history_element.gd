## History tracking element for card movement operations with precise undo support.
##
## HistoryElement stores complete state information for card movements to enable
## accurate undo/redo operations. It tracks source and destination containers,
## moved cards, and their original indices for precise state restoration.
##
## Key Features:
## - Complete movement state capture for reliable undo operations
## - Precise index tracking to restore original card positions
## - Support for multi-card movement operations
## - Detailed string representation for debugging and logging
##
## Used By:
## - CardManager for history management and undo operations
## - CardContainer.undo() for precise card position restoration
##
## Index Precision:
## The from_indices array stores the exact original positions of cards in their
## source container. This enables precise restoration even when multiple cards
## are moved simultaneously or containers have been modified since the operation.
##
## Usage:
## [codeblock]
## var history = HistoryElement.new()
## history.from = source_container
## history.to = target_container
## history.cards = [card1, card2]
## history.from_indices = [0, 2]  # Original positions in source
## [/codeblock]
class_name HistoryElement
extends Object

# Movement tracking data
## Source container where cards originated (null for newly created cards)
var from: CardContainer
## Destination container where cards were moved
var to: CardContainer
## Array of Card instances that were moved in this operation
var cards: Array
## Original indices of cards in the source container for precise undo restoration
var from_indices: Array


## Generates a detailed string representation of the history element for debugging.
## Includes container information, card details, and original indices.
## @returns: Formatted string with complete movement information
func get_string() -> String:
	var from_str = from.get_string() if from != null else "null"
	var to_str = to.get_string() if to != null else "null"
	
	# Build card list representation
	var card_strings = []
	for c in cards:
		card_strings.append(c.get_string())

	var cards_str = ""
	for i in range(card_strings.size()):
		cards_str += card_strings[i]
		if i < card_strings.size() - 1:
			cards_str += ", "
	
	# Format index array for display
	var indices_str = str(from_indices) if not from_indices.is_empty() else "[]"
	return "from: [%s], to: [%s], cards: [%s], indices: %s" % [from_str, to_str, cards_str, indices_str]
