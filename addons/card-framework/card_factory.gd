@tool
class_name CardFactory
extends Node
## Base Class for loading and making Card instances.


## Cache for card data. [method preload_card_data] should populate this at some
## point, and [method create_card] ideally would check for this.
var preloaded_cards : Dictionary = {}

var card_size: Vector2

## [param target]: The CardContainer where the card will be added.[br]
## Returns the created Card instance.
func create_card(card_name: String, target: CardContainer) -> Card:
	return null


## Preloads card data into the [member preloaded_cards] dictionary.
## This function should be called to initialize card data before creating cards.
func preload_card_data() -> void:
	pass
