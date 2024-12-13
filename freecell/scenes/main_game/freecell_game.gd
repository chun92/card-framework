class_name FreecellGame
extends Node

const suits = ["Heart", "Spade", "Diamond", "Club"]
const auto_move_timer_wating_time = 0.2
const game_generating_timer_waiting_time = 0.1

var freecells := []
var foundations := []
var tableaus := []
var all_cards := []

var card_factory: FreecellCardFactory
# XXX: temp magin number
var current_seed := 164

var auto_move_timer: Timer
var auto_move_target := {}
var auto_moving_map := {}

var game_generating_timer: Timer


@onready var card_manager = $CardManager
@onready var game_generator = $GameGenerator
@onready var start_position = $CardManager/StartPosition

func _ready() -> void:
	_set_containers()
	_set_ui_buttons()
	_set_auto_mover()
	_set_game_generating_timer()


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


func maximum_number_of_super_move(tableau: Tableau) -> int:
	var empty_freecells = _count_remaining_freecell()
	var empty_tableaus = _count_remaining_tableaus()
	var result = pow(2, empty_tableaus) * (empty_freecells + 1)
	if tableau != null and tableau.is_empty():
		@warning_ignore("integer_division")
		result = result / 2
	return result


func hold_multiple_cards(card: Card, tableau: Tableau):
	var current_card: Card = null
	var holding_card_list := []
	if tableau.has_card(card):
		var max_super_move = maximum_number_of_super_move(null)
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
			if current_card == card:
				break
	
	for target_card in holding_card_list:
		if target_card != card:
			target_card.start_hovering()
			target_card.set_holding()
	return

func update_all_tableaus_cards_can_be_interactwith(use_auto_move: bool = true):
	for tableau in tableaus:
		if tableau.is_initializing:
			continue
		_update_cards_can_be_interactwith(tableau)
		if use_auto_move:
			_check_auto_move(tableau)
	for freecell in freecells:
		if use_auto_move:
			_check_auto_move(freecell)

	var win_condition = _check_win_condition()
	if win_condition:
		print("You win!")
		# XXX: show win dialog
	
	var lose_condition = _check_lose_condition()
	if lose_condition:
		print("You lose!")
		# XXX: show lose dialog


func _update_cards_can_be_interactwith(tableau: Tableau):
	var current_card: Card = null
	var count := 0
	var max_super_move = maximum_number_of_super_move(null)
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

func _get_foundation(suit: PlayingCard.Suit) -> Foundation:
	match suit:
		PlayingCard.Suit.SPADE:
			return foundations[1]
		PlayingCard.Suit.HEART:
			return foundations[0]
		PlayingCard.Suit.DIAMOND:
			return foundations[2]
		PlayingCard.Suit.CLUB:
			return foundations[3]
		_:
			return null

func _get_minimum_number(a: Foundation, b: Foundation) -> int:
	var a_top_card = a.get_top_card()
	var b_top_card = b.get_top_card()
	var a_top_number = 0
	var b_top_number = 0
	if a_top_card != null:
		a_top_number = a_top_card.number
	if b_top_card != null:
		b_top_number = b_top_card.number
	return min(a_top_number, b_top_number)
	

func _get_minimum_number_in_foundation(card_color: PlayingCard.CardColor) -> int:
	if card_color == PlayingCard.CardColor.BLACK:
		return _get_minimum_number(_get_foundation(PlayingCard.Suit.SPADE), _get_foundation(PlayingCard.Suit.CLUB))
	elif card_color == PlayingCard.CardColor.RED:
		return _get_minimum_number(_get_foundation(PlayingCard.Suit.HEART), _get_foundation(PlayingCard.Suit.DIAMOND))
	else:
		return -1

func _check_auto_move(container):
	if container._held_cards.is_empty():
		return
	var top_card = container._held_cards.back()
	var suit = top_card.suit
	var card_color = top_card.card_color
	var opposite_color := PlayingCard.CardColor.NONE
	if card_color == PlayingCard.CardColor.BLACK:
		opposite_color = PlayingCard.CardColor.RED
	elif card_color == PlayingCard.CardColor.RED:
		opposite_color = PlayingCard.CardColor.BLACK
	
	var foundation = _get_foundation(suit)
	var top_card_of_foundation = foundation.get_top_card()
	
	var result := false
	if top_card_of_foundation == null:
		if top_card.number == 1:
			result = true
	else:
		var min_other_color_number = _get_minimum_number_in_foundation(opposite_color)
		if top_card_of_foundation.is_next_number(top_card) and top_card.number <= min_other_color_number + 1:
			result = true
	
	if result:
		auto_move_target = {
			"card": top_card,
			"foundation": foundation
		}
		if auto_moving_map.find_key(top_card):
			return
		auto_moving_map[top_card] = foundation
		_set_all_card_control(true)
		auto_move_timer.start(auto_move_timer_wating_time)


func _set_containers():
	for i in range(1, 5):
		var freecell = card_manager.get_node("Freecell_%d" % i)
		freecells.append(freecell)
		freecell.freecell_game = self
		
	for suit in suits:
		var foundation = card_manager.get_node("Foundation_%s" % suit)
		foundations.append(foundation)
		foundation.freecell_game = self
		
	for i in range(1, 9):
		var tableau = card_manager.get_node("Tableau_%d" % i)
		tableaus.append(tableau)
		tableau.freecell_game = self

func _set_auto_mover():
	auto_move_timer = Timer.new()
	auto_move_timer.wait_time = auto_move_timer_wating_time
	auto_move_timer.one_shot = true
	auto_move_timer.timeout.connect(_on_timeout)
	add_child(auto_move_timer)


func _set_game_generating_timer():
	game_generating_timer = Timer.new()
	game_generating_timer.wait_time = game_generating_timer_waiting_time
	game_generating_timer.one_shot = true
	add_child(game_generating_timer)


func _set_ui_buttons():
	var button_new_game = $Button_new_game
	button_new_game.connect("pressed", _new_game)
	var button_undo = $Button_undo
	button_undo.connect("pressed", card_manager.undo)


func _on_timeout():
	var target_card = auto_move_target["card"]
	var target_foundation = auto_move_target["foundation"]
	target_foundation.move_cards([target_card])
	auto_moving_map.erase(target_card)
	if auto_moving_map.size() == 0:
		_set_all_card_control(false)


func _new_game():
	# reset all cards
	for freecell in freecells:
		freecell.clear_cards()
	for foundation in foundations:
		foundation.clear_cards()
	for tableau in tableaus:
		tableau.clear_cards()
	start_position.clear_cards()
	all_cards.clear()
	auto_moving_map.clear()
	card_manager.reset_history()
		
	if card_factory == null:
		card_factory = $CardManager/FreecellCardFactory

	var deck = game_generator.deal(current_seed)
	var cards_str = game_generator.generate_cards(deck)
	
	for tableau in tableaus:
		tableau.is_initializing = true
	
	for i in range(cards_str.size() - 1, -1, -1):
		var card_name = cards_str[i]
		var card = card_factory.create_card(card_name, start_position)
		all_cards.append(card)

	var current_index := 0
	var offset := tableaus.size()
	for i in range(start_position._held_cards.size() - 1, -1, -1):
		var card = start_position._held_cards[i]
		var tableau = tableaus[current_index]
		tableau.move_cards([card], false)
		current_index = (current_index + 1) % offset
		game_generating_timer.start(game_generating_timer_waiting_time)
		await game_generating_timer.timeout
		
	for tableau in tableaus:
		tableau.is_initializing = false
		_update_cards_can_be_interactwith(tableau)
	

func _set_all_card_control(disable: bool):
	for card in all_cards:
		card.is_stop_control = disable

func _check_win_condition() -> bool:
	for foundation in foundations:
		if foundation._held_cards.size() != 13:
			return false
	return true

func _check_card_can_be_anywhere(card: Card) -> bool:
	for tableau in tableaus:
		if tableau._card_can_be_added([card]):
			return true
	for freecell in freecells:
		if freecell._card_can_be_added([card]):
			return true
	for foundation in foundations:
		if foundation._card_can_be_added([card]):
			return true
	return false

func _check_lose_condition() -> bool:
	for tableau in tableaus:
		var top_card = tableau.get_top_card()
		if top_card == null:
			return false
		if _check_card_can_be_anywhere(top_card):
			return false
	
	for freecell in freecells:
		if freecell.is_empty():
			return false
		if _check_card_can_be_anywhere(freecell.get_top_card()):
			return false
	
	return true
