class_name DropZone
extends Control


var sensor_size: Vector2: 
	set(value):
		sensor.size = value
var sensor_position: Vector2: 
	set(value):
		sensor.position = value
var sensor_texture : Texture:
	set(value):
		sensor.texture = value
var sensor_visible := true:
	set(value):
		sensor.visible = value
var accept_types: Array = []
var stored_sensor_size: Vector2
var stored_sensor_position: Vector2
var parent: Node
var sensor: Control

## global vertical lines to divide the sensing partitions, left to right direction
var horizontal_partition: Array
## global vertical lines to divide the sensing partitions, up to down direction
var vertical_partition: Array


func init(_parent: Node, accept_types: Array =[]):
	parent = _parent
	self.accept_types = accept_types

	if sensor == null:
		sensor = TextureRect.new()
		sensor.name = "Sensor"
		sensor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sensor.z_index = -1000
		add_child(sensor)

	stored_sensor_size = Vector2(0, 0)
	stored_sensor_position = Vector2(0, 0)
	horizontal_partition = []
	vertical_partition = []


func check_mouse_is_in_drop_zone() -> bool:
	var mouse_position = get_global_mouse_position()
	var result = sensor.get_global_rect().has_point(mouse_position)
	return result


func set_sensor(_size: Vector2, _position: Vector2, _texture: Texture, _visible: bool):
	sensor_size = _size
	sensor_position = _position
	stored_sensor_size = _size
	stored_sensor_position = _position
	sensor_texture = _texture
	sensor_visible = _visible


func set_sensor_size_flexibly(_size: Vector2, _position: Vector2):
	sensor_size = _size
	sensor_position = _position


func return_sensor_size():
	sensor_size = stored_sensor_size
	sensor_position = stored_sensor_position


func change_sensor_position_with_offset(offset: Vector2):
	sensor_position = stored_sensor_position + offset


func set_horizontal_partitions(positions: Array):
	horizontal_partition = positions


func set_vertical_partitions(positions: Array):
	vertical_partition = positions


func get_horizontal_layers() -> int:
	if not check_mouse_is_in_drop_zone():
		return -1

	if horizontal_partition == null or horizontal_partition.is_empty():
		return -1

	var mouse_position = get_global_mouse_position()
	
	var current_index := 0

	for i in range(horizontal_partition.size()):
		if mouse_position.x >= horizontal_partition[i]:
			current_index += 1
		else:
			break
	return current_index


func get_vertical_layers() -> int:
	if not check_mouse_is_in_drop_zone():
		return -1

	if vertical_partition == null or vertical_partition.is_empty():
		return -1

	var mouse_position = get_global_mouse_position()
	
	var current_index := 0

	for i in range(vertical_partition.size()):
		if mouse_position.y >= vertical_partition[i]:
			current_index += 1
		else:
			break
	return current_index
