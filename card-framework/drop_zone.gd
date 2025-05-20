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
var stored_sensor_size: Vector2
var stored_sensor_position: Vector2
var parent_card_container: CardContainer
var sensor: Control


func check_mouse_is_in_drop_zone() -> bool:
	var mouse_position = get_global_mouse_position()
	var result = sensor.get_global_rect().has_point(mouse_position)
	return result


func set_sensor(_size: Vector2, _position: Vector2, _texture: Texture, _visible: bool):
	if sensor == null:
		sensor = TextureRect.new()
		sensor.name = "Sensor"
		sensor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sensor.z_index = -1000
		add_child(sensor)
		
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
