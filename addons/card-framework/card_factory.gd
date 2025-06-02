@tool
class_name CardFactory
extends Node

var preloaded_cards = {}
var card_size: Vector2

# @param target: The CardContainer where the card will be added.
# @return: The created Card instance.
func create_card(card_name: String, target: CardContainer) -> Card:
	return null
	
# Preloads card data into the `preloaded_cards` dictionary.
# This function should be called to initialize card data before creating cards.
func preload_card_data() -> void:
	pass
