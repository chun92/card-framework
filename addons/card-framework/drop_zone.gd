## Interactive drop zone system with sensor partitioning and visual debugging.
##
## DropZone provides sophisticated drag-and-drop target detection with configurable
## sensor areas, partitioning systems, and visual debugging capabilities. It integrates
## with CardContainer to enable precise card placement and reordering operations.
##
## Key Features:
## - Flexible sensor sizing and positioning with dynamic adjustment
## - Vertical/horizontal partitioning for precise drop targeting
## - Visual debugging with colored outlines and partition indicators
## - Mouse detection with global coordinate transformation
## - Accept type filtering for specific draggable object types
##
## Partitioning System:
## - Vertical partitions: Divide sensor into left-right sections for card ordering
## - Horizontal partitions: Divide sensor into up-down sections for layered placement
## - Dynamic outline generation for visual feedback during development
##
## Usage:
## [codeblock]
## var drop_zone = DropZone.new()
## drop_zone.init(container, ["card"])
## drop_zone.set_sensor(Vector2(200, 300), Vector2.ZERO, null, false)
## drop_zone.set_vertical_partitions([100, 200, 300])
## [/codeblock]
class_name DropZone
extends Control



# Dynamic sensor properties with automatic UI synchronization
## Size of the drop sensor area
var sensor_size: Vector2: 
	set(value):
		sensor.size = value
		sensor_outline.size = value

## Position offset of the drop sensor relative to DropZone
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

## Controls visibility of debugging outlines for sensor and partitions
var sensor_outline_visible := false:
	set(value):
		sensor_outline.visible = value
		for outline in sensor_partition_outlines:
			outline.visible = value

# Core drop zone configuration and state
## Array of accepted draggable object types (e.g., ["card", "token"])
var accept_types: Array = []
## Original sensor size for restoration after dynamic changes
var stored_sensor_size: Vector2
## Original sensor position for restoration after dynamic changes  
var stored_sensor_position: Vector2
## Parent container that owns this drop zone
var parent: Node

# UI components
## Main sensor control for hit detection (invisible)
var sensor: Control
## Debug outline for visual sensor boundary indication
var sensor_outline: ReferenceRect
## Array of partition outline controls for debugging
var sensor_partition_outlines: Array = []

# Partitioning system for precise drop targeting
## Global vertical lines to divide sensing partitions (left to right direction)
var vertical_partition: Array
## Global horizontal lines to divide sensing partitions (up to down direction)
var horizontal_partition: Array


## Initializes the drop zone with parent reference and accepted drag types.
## Creates sensor and debugging UI components.
## @param _parent: Container that owns this drop zone
## @param accept_types: Array of draggable object types this zone accepts
func init(_parent: Node, accept_types: Array =[]):
	parent = _parent
	self.accept_types = accept_types

	# Create invisible sensor for hit detection
	if sensor == null:
		sensor = TextureRect.new()
		sensor.name = "Sensor"
		sensor.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sensor.z_index = CardFrameworkSettings.VISUAL_SENSOR_Z_INDEX  # Behind everything else
		add_child(sensor)

	# Create debugging outline (initially hidden)
	if sensor_outline == null:
		sensor_outline = ReferenceRect.new()
		sensor_outline.editor_only = false
		sensor_outline.name = "SensorOutline"
		sensor_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sensor_outline.border_color = CardFrameworkSettings.DEBUG_OUTLINE_COLOR
		sensor_outline.z_index = CardFrameworkSettings.VISUAL_OUTLINE_Z_INDEX
		add_child(sensor_outline)

	# Initialize default values
	stored_sensor_size = Vector2(0, 0)
	stored_sensor_position = Vector2(0, 0)
	vertical_partition = []
	horizontal_partition = []


## Checks if the mouse cursor is currently within the drop zone sensor area.
## @returns: True if mouse is inside the sensor bounds
func check_mouse_is_in_drop_zone() -> bool:
	var mouse_position = get_global_mouse_position()
	var result = sensor.get_global_rect().has_point(mouse_position)
	return result


## Configures the sensor with size, position, texture, and visibility settings.
## Stores original values for later restoration.
## @param _size: Size of the sensor area
## @param _position: Position offset from DropZone origin
## @param _texture: Optional texture for sensor visualization
## @param _visible: Whether sensor texture is visible (deprecated)
func set_sensor(_size: Vector2, _position: Vector2, _texture: Texture, _visible: bool):
	sensor_size = _size
	sensor_position = _position
	stored_sensor_size = _size
	stored_sensor_position = _position
	sensor_texture = _texture
	sensor_visible = _visible


## Dynamically adjusts sensor size and position without affecting stored values.
## Used for temporary sensor modifications that can be restored later.
## @param _size: New temporary sensor size
## @param _position: New temporary sensor position
func set_sensor_size_flexibly(_size: Vector2, _position: Vector2):
	sensor_size = _size
	sensor_position = _position


## Restores sensor to its original size and position from stored values.
## Used to undo temporary modifications made by set_sensor_size_flexibly.
func return_sensor_size():
	sensor_size = stored_sensor_size
	sensor_position = stored_sensor_position


## Adjusts sensor position by adding an offset to the stored position.
## @param offset: Vector2 offset to add to the original stored position
func change_sensor_position_with_offset(offset: Vector2):
	sensor_position = stored_sensor_position + offset


## Sets vertical partition lines for drop targeting and creates debug outlines.
## Vertical partitions divide the sensor into left-right sections for card ordering.
## @param positions: Array of global X coordinates for partition lines
func set_vertical_partitions(positions: Array):
	vertical_partition = positions
	
	# Clear existing partition outlines
	for outline in sensor_partition_outlines:
		outline.queue_free()
	sensor_partition_outlines.clear()
	
	# Create debug outline for each partition
	for i in range(vertical_partition.size()):
		var outline = ReferenceRect.new()
		outline.editor_only = false
		outline.name = "VerticalPartition" + str(i)
		outline.z_index = CardFrameworkSettings.VISUAL_OUTLINE_Z_INDEX
		outline.border_color = CardFrameworkSettings.DEBUG_OUTLINE_COLOR
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outline.size = Vector2(1, sensor.size.y)  # Vertical line full height
		
		# Convert global partition position to local coordinates
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
		outline.z_index = CardFrameworkSettings.VISUAL_OUTLINE_Z_INDEX
		outline.border_color = CardFrameworkSettings.DEBUG_OUTLINE_COLOR
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		outline.size = Vector2(sensor.size.x, 1)
		var local_y = horizontal_partition[i] - global_position.y
		outline.position = Vector2(sensor.position.x, local_y)
		outline.visible = sensor_outline.visible
		add_child(outline)
		sensor_partition_outlines.append(outline)


## Determines which vertical partition the mouse is currently in.
## Returns the partition index for precise drop targeting.
## @returns: Partition index (0-based) or -1 if outside sensor or no partitions
func get_vertical_layers() -> int:
	if not check_mouse_is_in_drop_zone():
		return -1

	if vertical_partition == null or vertical_partition.is_empty():
		return -1

	var mouse_position = get_global_mouse_position()
	
	# Count how many partition lines the mouse has crossed
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
