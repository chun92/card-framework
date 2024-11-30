extends Node


@onready var card_manager = $CardManager
@onready var card_factory = $CardManager/CardFactory
@onready var hand = $CardManager/Hand

func _get_randomized_card_list() -> Array:
	var suits = ["club", "spade", "diamond", "heart"]
	var values = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
	
	var card_list = []
	for suit in suits:
		for value in values:
			card_list.append("%s_%s" % [suit, value])
	
	card_list.shuffle()
	
	return card_list

func _on_card_create_button_pressed() -> void:
	var list = _get_randomized_card_list()
	card_factory.create_card(list.front(), hand)
