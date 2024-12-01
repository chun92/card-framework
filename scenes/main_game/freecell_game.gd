class_name FreecellGame
extends Node

func _ready() -> void:
	var button = $Button_new_game
	button.connect("pressed", _set_temp_game)
	
func _set_temp_game():
	var freecell_1 = $CardManager/Freecell_1
	var freecell_2 = $CardManager/Freecell_2
	var freecell_3 = $CardManager/Freecell_3
	var freecell_4 = $CardManager/Freecell_4
	var card_factory = $CardManager/FrecellCardFactory
	card_factory.create_card("diamond_A", freecell_1)
	card_factory.create_card("diamond_2", freecell_2)
	card_factory.create_card("diamond_3", freecell_3)
	card_factory.create_card("diamond_4", freecell_4)
