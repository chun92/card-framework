class_name SaveService
extends RefCounted

const ROOT := "user://"


static func save_json(file_name: String, data: Variant) -> bool:
	var path := ROOT + file_name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveService: cannot write %s (error %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	# Always close explicitly. On the web target this is what flushes to IndexedDB.
	file.close()
	return true


static func load_json(file_name: String) -> Variant:
	var path := ROOT + file_name
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveService: cannot read %s (error %d)" % [path, FileAccess.get_open_error()])
		return null
	var text := file.get_as_text()
	file.close()
	return JSON.parse_string(text)


static func exists(file_name: String) -> bool:
	return FileAccess.file_exists(ROOT + file_name)
