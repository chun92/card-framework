class_name DraggableObject
extends Control


const Z_INDEX_OFFSET_WHEN_HOLDING = 1000


## The speed at which the objects moves.
@export var moving_speed: int = 2000
## Whether the object can be interacted with.
@export var can_be_interacted_with: bool = true
## The distance the object hovers when interacted with.
@export var hover_distance: int = 10


var is_hovering: bool = false
var is_pressed: bool = false
var is_holding: bool = false
var stored_z_index: int:
	set(value):
		z_index = value
		stored_z_index = value
var is_moving_to_destination: bool = false
var current_holding_mouse_position: Vector2
var move_tween: Tween
var destination_degree: float
var target_destination: Vector2  # Target position passed to move() function
var target_rotation: float       # Target rotation passed to move() function
var original_destination: Vector2
var original_rotation: float
var is_returning_to_original: bool = false


func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	connect("mouse_entered", _on_mouse_enter)
	connect("mouse_exited", _on_mouse_exit)
	connect("gui_input", _on_gui_input)
	
	original_destination = global_position
	original_rotation = rotation
	stored_z_index = z_index


func _process(delta: float) -> void:
	if is_holding:
		start_hovering()
		global_position = get_global_mouse_position() - current_holding_mouse_position


func _finish_move() -> void:
	# Complete movement processing
	is_moving_to_destination = false
	z_index = stored_z_index
	rotation = destination_degree
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Update original position and rotation only when not returning to original
	# Important: Use original target values from move() instead of global_position
	if not is_returning_to_original:
		original_destination = target_destination
		original_rotation = target_rotation
	
	# Reset return flag
	is_returning_to_original = false
	
	# Call inherited class callback
	_on_move_done()


func _on_move_done() -> void:
	# This function can be overridden by subclasses to handle when the move is done.
	pass


func _on_mouse_enter() -> void:
	if not is_moving_to_destination and can_be_interacted_with:
		start_hovering()


func _on_mouse_exit() -> void:
	if is_pressed:
		return
	end_hovering(true)


func _on_gui_input(event: InputEvent) -> void:
	if not can_be_interacted_with:
		return
	
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)


func move(target_destination: Vector2, degree: float) -> void:
	# Skip if current position and rotation match target
	if global_position == target_destination and rotation == degree:
		return

	# Stop existing movement
	if move_tween and move_tween.is_valid():
		move_tween.kill()
	
	# End hover state immediately to prevent state conflicts
	end_hovering(false)
	
	# Store target position and rotation for original value preservation
	self.target_destination = target_destination
	self.target_rotation = degree
	
	# Initial setup
	rotation = 0
	destination_degree = degree
	is_moving_to_destination = true
	z_index = stored_z_index + Z_INDEX_OFFSET_WHEN_HOLDING
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Smooth Tween-based movement with dynamic duration based on moving_speed
	var distance = global_position.distance_to(target_destination)
	var duration = distance / moving_speed
	
	move_tween = create_tween()
	move_tween.tween_property(self, "global_position", target_destination, duration)
	move_tween.tween_callback(_finish_move)


func start_hovering() -> void:
	if not is_hovering:
		is_hovering = true
		z_index += Z_INDEX_OFFSET_WHEN_HOLDING
		position.y -= hover_distance


func end_hovering(restore_object_position: bool) -> void:
	if is_hovering:
		z_index = stored_z_index
		is_hovering = false
		if restore_object_position:
			position.y += hover_distance


func set_holding() -> void:
	is_holding = true
	current_holding_mouse_position = get_local_mouse_position()
	z_index = stored_z_index + Z_INDEX_OFFSET_WHEN_HOLDING
	rotation = 0


func set_releasing() -> void:
	is_holding = false


func _handle_mouse_button(mouse_event: InputEventMouseButton) -> void:
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	if is_moving_to_destination:
		return
	
	if mouse_event.is_pressed():
		_handle_mouse_pressed()
	
	if mouse_event.is_released():
		_handle_mouse_released()


func _handle_mouse_pressed() -> void:
	is_pressed = true
	set_holding()


func _handle_mouse_released() -> void:
	is_pressed = false
