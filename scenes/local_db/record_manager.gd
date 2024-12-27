extends Node

const RECORDS_PATH = "user://record_table.json"
const CURRENT_GAME_INFO_PATH = "user://current_game_info.json"
var record_table: Dictionary = {}
var running_game: Dictionary = {}

func _ready():
	load_table()
	check_running_game_info()
	print("table: %s" % JSON.stringify(record_table, "  "))


func load_table():
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


func save_table():
	var json_str = JSON.stringify(record_table)
	var file = FileAccess.open(RECORDS_PATH, FileAccess.WRITE)
	file.store_string(json_str)
	file.close()


func make_record(game_seed: int, move_count: int, undo_count: int, game_time: int, score: int, game_state: FreecellGame.GameState):
	var record_id = generate_unique_id()
	while record_table.has(record_id):
		record_id = generate_unique_id()

	var record = {
		"game_date": Time.get_datetime_dict_from_system(),
		"game_seed": game_seed,
		"move_count": move_count,
		"undo_count": undo_count,
		"game_time": game_time,
		"score": score,
		"game_state": game_state
	}
	
	print("save_record[%s]: %s" % [record_id, JSON.stringify(record_table, "  ")])

	record_table[record_id] = record
	save_table()
	remove_running_game_info()


func generate_unique_id() -> String:
	var id = ""
	var hex = "0123456789abcdef"
	for i in range(10):
		id += hex[randi() % 16]
	return id


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


func save_running_game_info(game_seed: int, move_count: int, undo_count: int, game_time: int, score: int, game_state: FreecellGame.GameState):
	if game_state == FreecellGame.GameState.LOSE:
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


func check_running_game_info():
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


func remove_running_game_info():
	var game_info = {}
	var json_str = JSON.stringify(game_info)
	var file = FileAccess.open(CURRENT_GAME_INFO_PATH, FileAccess.WRITE)
	file.store_string(json_str)
	file.close()
