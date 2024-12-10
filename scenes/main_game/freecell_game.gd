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
		freecell.freecell_game = self
		
	var suits = ["Heart", "Spade", "Diamond", "Club"]
	for suit in suits:
		var foundation = card_manager.get_node("Foundation_%s" % suit)
		foundations.append(foundation)
		foundation.freecell_game = self
		
	for i in range(1, 9):
		var tableau = card_manager.get_node("Tableau_%d" % i)
		tableaus.append(tableau)
		tableau.freecell_game = self
	
	CardFrameworkSignalBus.card_dropped.connect(_on_card_dropped)

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
		_update_cards_can_be_interactwith(tableau)


func _on_card_dropped(_card: Card, _target_card_container: CardContainer) -> void:
	for tableau in tableaus:
		_update_cards_can_be_interactwith(tableau)


func _count_remaining_freecell() -> int:
	var count = 0
	for freecell in freecells:
		if freecell.is_empty():
			count += 1
	return count


func _count_remaining_tableaus() -> int:
	var count = 0
	for tableau in tableaus:
		if tableau.is_empty():
			count += 1
	return count


func _maximum_number_of_super_move(tableau: Tableau) -> int:
	var empty_freecells = _count_remaining_freecell()
	var empty_tableaus = _count_remaining_tableaus()
	var result = pow(2, empty_tableaus) * (empty_freecells + 1)
	if tableau != null and tableau.is_empty():
		@warning_ignore("integer_division")
		result = result / 2
	print("empty_freecells: %d, empty_tableaus: %d, result: %d" % [empty_freecells, empty_tableaus, result])
	return result


func hold_multiple_cards(card: Card, tableau: Tableau):
	var current_card: Card = null
	var holding_card_list := []
	if tableau.has_card(card):
		var max_super_move = _maximum_number_of_super_move(null)
		for i in range(tableau._held_cards.size() - 1, -1, -1):
			var target_card = tableau._held_cards[i]
			if current_card == null:
				current_card = target_card
				holding_card_list.append(current_card)
			elif holding_card_list.size() >= max_super_move:
				holding_card_list.clear()
				return 
			elif current_card.is_next_number(target_card) and current_card.is_different_color(target_card):
				current_card = target_card
				holding_card_list.append(current_card)
				if current_card == card:
					break
			else:
				holding_card_list.clear()
				return
	
	for target_card in holding_card_list:
		if target_card != card:
			target_card.start_hovering()
			target_card.set_holding()
	return


func _update_cards_can_be_interactwith(tableau: Tableau):
	var current_card: Card = null
	var count := 0
	var max_super_move = _maximum_number_of_super_move(null)
	for card in tableau._held_cards:
		card.can_be_interact_with = false
	for i in range(tableau._held_cards.size() - 1, -1, -1):
		var target_card = tableau._held_cards[i]
		if current_card == null:
			current_card = target_card
			target_card.can_be_interact_with = true
			count += 1
		elif count >= max_super_move:
			return
		elif current_card.is_next_number(target_card) and current_card.is_different_color(target_card):
			current_card = target_card
			target_card.can_be_interact_with = true
			count += 1
		else:
			return
		if current_card.number == PlayingCard.Number._K:
			return
