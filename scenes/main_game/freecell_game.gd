class_name FreecellGame
extends Node

var freecells := []
var foundations := []
var tableaus := []
var card_factory: FreecellCardFactory
# XXX: temp magin number
var current_seed := 617

@onready var card_manager = $CardManager
@onready var game_generator = $GameGenerator

func _ready() -> void:
	for i in range(1, 5):
		var freecell = card_manager.get_node("Freecell_%d" % i)
		freecells.append(freecell)
		
	foundations.append(card_manager.get_node("Foundation_Heart"))
	foundations.append(card_manager.get_node("Foundation_Spade"))
	foundations.append(card_manager.get_node("Foundation_Diamond"))
	foundations.append(card_manager.get_node("Foundation_Club"))
		
	for i in range(1, 9):
		var tableau = card_manager.get_node("Tableau_%d" % i)
		tableaus.append(tableau)
		
	var button = $Button_new_game
	button.connect("pressed", _new_game)

func _new_game():
	# reset all cards
	for freecell in freecells:
		freecell.clear_cards()
	
	for foundation in foundations:
		foundation.clear_cards()
	
	for tableau in tableaus:
		tableau.clear_cards()
		
	if card_factory == null:
		card_factory = $CardManager/FreecellCardFactory

	var deck = game_generator.deal(current_seed)
	var cards_str = game_generator.generate_cards(deck)
	
	for tableau in tableaus:
		tableau.is_initializing = true
	
	var current_index := 0
	var offset := tableaus.size()
	for card_name in cards_str:
		var tableau = tableaus[current_index]
		card_factory.create_card(card_name, tableau)
		current_index = (current_index + 1) % offset
		
	for tableau in tableaus:
		tableau.is_initializing = false
