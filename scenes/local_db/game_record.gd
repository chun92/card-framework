class_name GameRecord
extends Object

var _game_date: Dictionary
var _game_seed: int
var _move_count: int
var _undo_count: int
var _game_time: int
var _score: int
var _game_state := FreecellGame.GameState.PLAYING

func get_record(game_seed: int, move_count: int, undo_count: int, game_time: int, score: int, game_state: FreecellGame.GameState):
	_game_date = Time.get_datetime_dict_from_system()
	_game_seed = game_seed
	_move_count = move_count
	_undo_count = undo_count
	_game_time = game_time
	_score = score
	_game_state = game_state
