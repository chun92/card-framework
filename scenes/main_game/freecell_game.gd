class_name FreecellGame
extends Node


enum GameState {WIN = 1, LOSE = 2, PLAYING = 3}


const suits = ["Heart", "Spade", "Diamond", "Club"]
const auto_move_timer_wating_time = 0.2
const game_generating_timer_waiting_time = 0.05


var freecells := []
var foundations := []
var tableaus := []
var all_cards := []
var card_factory: FreecellCardFactory
var game_seed := 0
var is_creating_new_game := false
var auto_move_timer: Timer
var auto_move_target := {}
var auto_moving_map := {}
var game_generating_timer: Timer
var elapsed_time := 0
var game_timer: Timer
var move_count := 0
var undo_count := 0
var score := 0
var game_state := GameState.PLAYING
var is_game_running := false
var record_manager: RecordManager
var menu_scene = load("res://freecell/scenes/menu/menu.tscn")


@onready var card_manager = $CardManager
@onready var game_generator = $GameGenerator
@onready var start_position = $CardManager/StartPosition
@onready var time_display = $Time
@onready var score_display = $Score
@onready var restart_game_dialog = $RestartGameDialog
@onready var go_to_menu_dialog = $GoToMenuDialog
@onready var information = $Information


func _ready() -> void:
	_set_record_manager()
	_set_containers()
	_set_ui_buttons()
	_set_auto_mover()
	_set_game_generating_timer()
	_set_game_timer()
	_update_information()


func maximum_number_of_super_move(tableau: Tableau) -> int:
	var empty_freecells = _count_remaining_freecell()
	var empty_tableaus = _count_remaining_tableaus()
	var result = pow(2, empty_tableaus) * (empty_freecells + 1)
	if tableau != null and tableau.is_empty():
		@warning_ignore("integer_division")
		result = result / 2
	return result


func hold_multiple_cards(card: Card, tableau: Tableau) -> void:
	var current_card: Card = null
	var holding_card_list := []
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


func update_all_tableaus_cards_can_be_interactwith(use_auto_move: bool = true) -> void:
	for tableau in tableaus:
		if tableau.is_initializing:
			continue
		_update_cards_can_be_interactwith(tableau)
		if use_auto_move:
			_check_auto_move(tableau)
	for freecell in freecells:
		if use_auto_move:
			_check_auto_move(freecell)

	_update_score()
	game_state = _get_game_state()
	
	match game_state:
		GameState.WIN:
			_show_result_popup(true)
			_end_game()
		GameState.LOSE:
			_show_result_popup(false)
			_end_game()
		GameState.PLAYING:
			pass
	_update_information()


func new_game() -> void:
	if is_game_running:
		game_state = GameState.LOSE
		_end_game()
	if is_creating_new_game:
		return
	is_creating_new_game = true
	if game_timer != null:
		game_timer.stop()
	_set_elapsed_time(0)
	_reset_cards_in_game()
	await _generate_cards()
	_start_game()
	is_creating_new_game = false
	is_game_running = true


func _get_game_state() -> GameState:
	var win_condition = _check_win_condition()
	if win_condition:
		return GameState.WIN
	
	var lose_condition = _check_lose_condition()
	if lose_condition:
		return GameState.LOSE
	
	return GameState.PLAYING


func _update_cards_can_be_interactwith(tableau: Tableau) -> void:
	var current_card: Card = null
	var count := 0
	var max_super_move = maximum_number_of_super_move(null)
	for card in tableau._held_cards:
		card.can_be_interacted_with = false
	for i in range(tableau._held_cards.size() - 1, -1, -1):
		var target_card = tableau._held_cards[i]
		if current_card == null:
			current_card = target_card
			target_card.can_be_interacted_with = true
			count += 1
		elif count >= max_super_move:
			return
		elif current_card.is_next_number(target_card) and current_card.is_different_color(target_card):
			current_card = target_card
			target_card.can_be_interacted_with = true
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


func _check_auto_move(container) -> void:
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


func _set_containers() -> void:
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


func _set_auto_mover() -> void:
	auto_move_timer = Timer.new()
	auto_move_timer.wait_time = auto_move_timer_wating_time
	auto_move_timer.one_shot = true
	auto_move_timer.timeout.connect(_on_timeout)
	add_child(auto_move_timer)


func _set_game_generating_timer() -> void:
	game_generating_timer = Timer.new()
	game_generating_timer.wait_time = game_generating_timer_waiting_time
	game_generating_timer.one_shot = true
	add_child(game_generating_timer)


func _set_elapsed_time(time) -> void:
	elapsed_time = time
	time_display.text = str(elapsed_time)


func _set_game_timer() -> void:
	if game_timer == null:
		game_timer = Timer.new()
		game_timer.wait_time = 1.0
		game_timer.one_shot = false
		game_timer.timeout.connect(_on_game_timer_timeout)
		add_child(game_timer)
	_set_elapsed_time(0)


func _on_game_timer_timeout() -> void:
	_set_elapsed_time(elapsed_time + 1)
	_update_information()


func _start_game() -> void:
	move_count = 0
	undo_count = 0
	score = 0
	_set_elapsed_time(0)
	game_timer.start()
	_update_information()


func _end_game() -> void:
	game_timer.stop()
	record_manager.make_record(game_seed, move_count, undo_count, elapsed_time, score, game_state)
	print("move: %d, undo: %d, score: %d, time: %d" % [move_count, undo_count, score, elapsed_time])
	is_game_running = false


func _update_score() -> void:
	score = 0
	for foundation in foundations:
		score += foundation._held_cards.size() * 10
	score -= move_count
	score -= undo_count * 3
	score_display.text = str(score)
	_update_information()


func _set_record_manager() -> void:
	var node = get_tree().root.get_node("RecordManager")
	record_manager = node as RecordManager


func _on_button_restart_game_pressed() -> void:
	if is_game_running:
		restart_game_dialog.popup_centered()
	else:
		new_game()


func _on_button_undo_pressed() -> void:
	if is_game_running:
		card_manager.undo()


func _on_button_menu_pressed() -> void:
	if is_game_running:
		go_to_menu_dialog.popup_centered()
	else:
		_go_to_menu()


func _set_ui_buttons() -> void:
	var button_restart_game = $ButtonRestartGame
	button_restart_game.connect("pressed", _on_button_restart_game_pressed)
	var button_undo = $ButtonUndo
	button_undo.connect("pressed", _on_button_undo_pressed)
	var button_menu = $ButtonMenu
	button_menu.connect("pressed", _on_button_menu_pressed)
	restart_game_dialog.connect("confirmed", new_game)
	go_to_menu_dialog.connect("confirmed", _go_to_menu)


func _on_timeout() -> void:
	var target_card = auto_move_target["card"]
	var target_foundation = auto_move_target["foundation"]
	target_foundation.auto_move_cards([target_card])
	auto_moving_map.erase(target_card)
	if auto_moving_map.size() == 0:
		_set_all_card_control(false)
	_update_information()


func _reset_cards_in_game() -> void:
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


func _generate_cards() -> void:
	var deck = game_generator.deal(game_seed)
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
		tableau.init_move_cards([card], false)
		current_index = (current_index + 1) % offset
		game_generating_timer.start(game_generating_timer_waiting_time)
		await game_generating_timer.timeout
		
	for tableau in tableaus:
		tableau.is_initializing = false
		_update_cards_can_be_interactwith(tableau)


func _go_to_menu() -> void:
	if is_game_running:
		game_state = GameState.LOSE
		_end_game()
	var menu_instance = menu_scene.instantiate()
	get_tree().root.add_child(menu_instance)
	get_node("/root/FreecellGame").queue_free()
	

func _set_all_card_control(disable: bool) -> void:
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


func _update_information() -> void:
	var text = "seed: " + str(game_seed) + \
		",  move: " + str(move_count) + \
		",  undo: " + str(undo_count) + \
		",  time: " + str(elapsed_time) + \
		",  score: " + str(score)
	
	match game_state:
		GameState.WIN:
			text += ",  state: win"
		GameState.LOSE:
			text += ",  state: lose"
		GameState.PLAYING:
			text += ",  state: playing"
	
	information.text = text
	record_manager.save_running_game_info(game_seed, move_count, undo_count, elapsed_time, score, game_state)


func _show_result_popup(is_win: bool) -> void:
	var dialog = $ResultDialog  # The AcceptDialog node
	var body_text = dialog.get_node("BodyText") as RichTextLabel
	
	if is_win:
		dialog.title = "Congratulations!"
	else:
		dialog.title = "Game Over"

	body_text.bbcode_enabled = true
	body_text.clear()

	var win_text = ""
	if is_win:
		win_text = "[color=green]Win[/color]"
	else:
		win_text = "[color=red]Lose[/color]"
	
	var text_body = ""
	text_body += "Result:\t\t%s\n" % win_text
	text_body += "Seed:\t\t\t%d\n" % game_seed
	text_body += "Time:\t\t\t%d\n" % elapsed_time
	text_body += "Score:\t\t\t%d\n" % score
	text_body += "Move:\t\t\t%d\n" % move_count
	text_body += "Undo:\t\t\t%d\n" % undo_count

	body_text.bbcode_text = text_body

	dialog.popup_centered()
