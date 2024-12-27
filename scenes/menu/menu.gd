extends Node


var game_scene = preload("res://freecell/scenes/main_game/freecell_game.tscn")
var statistics_scene = preload("res://freecell/scenes/menu/statistics.tscn")
@onready var seed_node = $NewGame/Seed
@onready var seed_warning = $SeedWarning


func _ready():
	_set_ui_buttons()


func _set_ui_buttons():
	var button_new_game = $NewGame
	button_new_game.connect("pressed", _new_game)
	var button_statistics = $Statistics
	button_statistics.connect("pressed", _go_to_statistics)
	var button_credits = $Credits
	button_credits.connect("pressed", _go_to_credits)
	var button_exit = $Exit
	button_exit.connect("pressed", _exit)
	


func _get_seed():
	var text = seed_node.text
	if text == "" or text == "-1":
		return randi() % 1000000 + 1
	
	if not text.is_valid_int():
		return 0
		
	var game_seed = text.to_int()
	if game_seed >= 1 and game_seed <= 1000000:
		return game_seed
	
	return 0


func _new_game():
	var game_seed = _get_seed()
	if game_seed == 0:
		seed_warning.popup_centered()
		return
	
	var game_instance = game_scene.instantiate()
	game_instance.game_seed = game_seed
	get_tree().root.add_child(game_instance)
	game_instance.new_game()
	get_node("/root/Menu").queue_free()


func _go_to_statistics():
	var statistics_instance = statistics_scene.instantiate()
	get_tree().root.add_child(statistics_instance)
	get_node("/root/Menu").queue_free()
	

func _go_to_credits():
	pass
	

func _exit():
	get_tree().quit()
