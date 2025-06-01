class_name RecordManager
extends Node

const RECORDS_PATH = "user://record_table.json"
const CURRENT_GAME_INFO_PATH = "user://current_game_info.json"


var record_table: Dictionary = {}
var next_id := 0 
var running_game: Dictionary = {}


func _ready() -> void:
	load_table()
	check_running_game_info()


func load_table() -> void:
	if FileAccess.file_exists(RECORDS_PATH):
		var file = FileAccess.open(RECORDS_PATH, FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		var parsed = JSON.parse_string(content)
		if parsed != null:
			record_table = parsed
		else:
			push_error("Failed to parse JSON: %s" % parsed.error_string)
	else:
		record_table = {}


func save_table() -> void:
	var json_str = JSON.stringify(record_table)
	var file = FileAccess.open(RECORDS_PATH, FileAccess.WRITE)
	file.store_string(json_str)
	file.close()


func make_record(game_seed: int, move_count: int, undo_count: int, game_time: int, score: int, game_state: FreecellGame.GameState) -> void:
	var record_id = ""
	while true:
		var candidate_id = "%016d" % next_id
		
		if not record_table.has(candidate_id):
			record_id = candidate_id
			next_id += 1
			break
		else:
			next_id += 1

	var record = {
		"game_date": Time.get_datetime_dict_from_system(),
		"game_seed": game_seed,
		"move_count": move_count,
		"undo_count": undo_count,
		"game_time": game_time,
		"score": score,
		"game_state": game_state
	}
	
	print("save_record[%s]: %s" % [record_id, JSON.stringify(record, "  ")])

	record_table[record_id] = record
	save_table()
	remove_running_game_info()


func get_record(record_id: String) -> Dictionary:
	if record_table.has(record_id):
		return record_table[record_id]
	return {}


func get_all_records() -> Dictionary:
	return record_table


func remove_record(record_id: String) -> bool:
	if record_table.has(record_id):
		return record_table.erase(record_id)
	else:
		return false


func remove_all():
	record_table = {}
	save_table()


func save_running_game_info(game_seed: int, move_count: int, undo_count: int, game_time: int, score: int, game_state: FreecellGame.GameState) -> void:
	if game_state != FreecellGame.GameState.PLAYING:
		return

	var game_info = {
		"game_date": Time.get_datetime_dict_from_system(),
		"game_seed": game_seed,
		"move_count": move_count,
		"undo_count": undo_count,
		"game_time": game_time,
		"score": score,
		"game_state": game_state
	}
	var json_str = JSON.stringify(game_info)
	var file = FileAccess.open(CURRENT_GAME_INFO_PATH, FileAccess.WRITE)
	file.store_string(json_str)
	file.close()


func check_running_game_info() -> void:
	if FileAccess.file_exists(CURRENT_GAME_INFO_PATH):
		var file = FileAccess.open(CURRENT_GAME_INFO_PATH, FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		var parsed = JSON.parse_string(content)
		if parsed != null:
			var game_info = parsed
			if game_info.has('game_seed'):
				make_record(game_info['game_seed'], 
					game_info['move_count'],
					game_info['undo_count'],
					game_info['game_time'],
					game_info['score'],
					FreecellGame.GameState.LOSE)
		else:
			push_error("Failed to parse JSON: %s" % parsed.error_string)


func remove_running_game_info() -> void:
	var game_info = {}
	var json_str = JSON.stringify(game_info)
	var file = FileAccess.open(CURRENT_GAME_INFO_PATH, FileAccess.WRITE)
	file.store_string(json_str)
	file.close()
