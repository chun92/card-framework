class_name DropZone
extends Control


const SENSOR_OUTLINE_Z_INDEX := 1200
const SENSOR_OUTLINE_COLOR := Color(1, 0, 0, 1)


var sensor_size: Vector2: 
	set(value):
		sensor.size = value
		sensor_outline.size = value
var sensor_position: Vector2: 
	set(value):
		sensor.position = value
		sensor_outline.position = value
## @deprecated: Since it was designed to debug the sensor, please use sensor_outline_visible instead.
var sensor_texture : Texture:
	set(value):
		sensor.texture = value
## @deprecated: Since it was designed to debug the sensor, please use sensor_outline_visible instead.
var sensor_visible := true:
	set(value):
		sensor.visible = value
var sensor_outline_visible := false:
	set(value):
		sensor_outline.visible = value
		for outline in sensor_partition_outlines:
			outline.visible = value

var accept_types: Array = []
var stored_sensor_size: Vector2
var stored_sensor_position: Vector2
var parent: Node
var sensor: Control
var sensor_outline: ReferenceRect
var sensor_partition_outlines: Array = []

## global vertical lines to divide the sensing partitions, left to right direction
var vertical_partition: Array
## global horizontal lines to divide the sensing partitions, up to down direction
var horizontal_partition: Array


func init(_parent: Node, accept_types: Array =[]):
	parent = _parent
	self.accept_types = accept_types

	if sensor == null:
		sensor = TextureRect.new()
		sensor.name = "Sensor"
		sensor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sensor.z_index = -1000
		add_child(sensor)

	if sensor_outline == null:
		sensor_outline = ReferenceRect.new()
		sensor_outline.editor_only = false
		sensor_outline.name = "SensorOutline"
		sensor_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sensor_outline.border_color = SENSOR_OUTLINE_COLOR
		sensor_outline.z_index = SENSOR_OUTLINE_Z_INDEX
		add_child(sensor_outline)

	stored_sensor_size = Vector2(0, 0)
	stored_sensor_position = Vector2(0, 0)
	vertical_partition = []
	horizontal_partition = []


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


func set_vertical_partitions(positions: Array):
	vertical_partition = positions
	# clear existing outlines
	for outline in sensor_partition_outlines:
		outline.queue_free()
	sensor_partition_outlines.clear()
	for i in range(vertical_partition.size()):
		var outline = ReferenceRect.new()
		outline.editor_only = false
		outline.name = "VerticalPartition" + str(i)
		outline.z_index = SENSOR_OUTLINE_Z_INDEX
		outline.border_color = SENSOR_OUTLINE_COLOR
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outline.size = Vector2(1, sensor.size.y)
		var local_x = vertical_partition[i] - global_position.x
		outline.position = Vector2(local_x, sensor.position.y)
		outline.visible = sensor_outline.visible
		add_child(outline)
		sensor_partition_outlines.append(outline)


func set_horizontal_partitions(positions: Array):
	horizontal_partition = positions
	# clear existing outlines
	for outline in sensor_partition_outlines:
		outline.queue_free()
	sensor_partition_outlines.clear()
	for i in range(horizontal_partition.size()):
		var outline = ReferenceRect.new()
		outline.editor_only = false
		outline.name = "HorizontalPartition" + str(i)
		outline.z_index = SENSOR_OUTLINE_Z_INDEX
		outline.border_color = SENSOR_OUTLINE_COLOR
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outline.size = Vector2(sensor.size.x, 1)
		var local_y = horizontal_partition[i] - global_position.y
		outline.position = Vector2(sensor.position.x, local_y)
		outline.visible = sensor_outline.visible
		add_child(outline)
		sensor_partition_outlines.append(outline)


func get_vertical_layers() -> int:
	if not check_mouse_is_in_drop_zone():
		return -1

	if vertical_partition == null or vertical_partition.is_empty():
		return -1

	var mouse_position = get_global_mouse_position()
	
	var current_index := 0

	for i in range(vertical_partition.size()):
		if mouse_position.x >= vertical_partition[i]:
			current_index += 1
		else:
			break
	return current_index


func get_horizontal_layers() -> int:
	if not check_mouse_is_in_drop_zone():
		return -1

	if horizontal_partition == null or horizontal_partition.is_empty():
		return -1

	var mouse_position = get_global_mouse_position()
	
	var current_index := 0

	for i in range(horizontal_partition.size()):
		if mouse_position.y >= horizontal_partition[i]:
			current_index += 1
		else:
			break
	return current_index
