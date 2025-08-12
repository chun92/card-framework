class_name DraggableObject
extends Control

enum DraggableState {
	IDLE,       # Default state - no interaction
	HOVERING,   # Mouse over state - visual feedback
	HOLDING,    # Dragging state - follows mouse
	MOVING      # Programmatic move state - ignores input
}

const Z_INDEX_OFFSET_WHEN_HOLDING = 1000


## The speed at which the objects moves.
@export var moving_speed: int = 2000
## Whether the object can be interacted with.
@export var can_be_interacted_with: bool = true
## The distance the object hovers when interacted with.
@export var hover_distance: int = 10


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
var current_state: DraggableState = DraggableState.IDLE

# State transition rules
var allowed_transitions = {
	DraggableState.IDLE: [DraggableState.HOVERING, DraggableState.HOLDING, DraggableState.MOVING],
	DraggableState.HOVERING: [DraggableState.IDLE, DraggableState.HOLDING, DraggableState.MOVING],
	DraggableState.HOLDING: [DraggableState.IDLE, DraggableState.MOVING],
	DraggableState.MOVING: [DraggableState.IDLE]
}


func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	connect("mouse_entered", _on_mouse_enter)
	connect("mouse_exited", _on_mouse_exit)
	connect("gui_input", _on_gui_input)
	
	original_destination = global_position
	original_rotation = rotation
	stored_z_index = z_index


# Safe state transition function
func change_state(new_state: DraggableState) -> bool:
	if new_state == current_state:
		return true
	
	if not new_state in allowed_transitions[current_state]:
		return false
	
	# Clean up previous state
	_exit_state(current_state)
	
	var old_state = current_state
	current_state = new_state
	
	# Enter new state
	_enter_state(new_state, old_state)
	
	return true


# Handle state entry
func _enter_state(state: DraggableState, from_state: DraggableState) -> void:
	match state:
		DraggableState.IDLE:
			z_index = stored_z_index
			mouse_filter = Control.MOUSE_FILTER_STOP
			
		DraggableState.HOVERING:
			z_index = stored_z_index + Z_INDEX_OFFSET_WHEN_HOLDING
			position.y -= hover_distance
			
		DraggableState.HOLDING:
			current_holding_mouse_position = get_local_mouse_position()
			z_index = stored_z_index + Z_INDEX_OFFSET_WHEN_HOLDING
			rotation = 0
			position.y -= hover_distance  # Maintain hover effect while holding
			
		DraggableState.MOVING:
			# Always ensure high z_index for moving cards (auto move and manual move)
			z_index = stored_z_index + Z_INDEX_OFFSET_WHEN_HOLDING
			mouse_filter = Control.MOUSE_FILTER_IGNORE


# Handle state exit
func _exit_state(state: DraggableState) -> void:
	match state:
		DraggableState.HOVERING:
			z_index = stored_z_index
			position.y += hover_distance
			
		DraggableState.HOLDING:
			z_index = stored_z_index
			position.y += hover_distance
			
		DraggableState.MOVING:
			mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	match current_state:
		DraggableState.HOLDING:
			global_position = get_global_mouse_position() - current_holding_mouse_position


func _finish_move() -> void:
	# Complete movement processing
	is_moving_to_destination = false
	rotation = destination_degree
	
	# Update original position and rotation only when not returning to original
	# Important: Use original target values from move() instead of global_position
	if not is_returning_to_original:
		original_destination = target_destination
		original_rotation = target_rotation
	
	# Reset return flag
	is_returning_to_original = false
	
	# End MOVING state - return to IDLE
	change_state(DraggableState.IDLE)
	
	# Call inherited class callback
	_on_move_done()


func _on_move_done() -> void:
	# This function can be overridden by subclasses to handle when the move is done.
	pass


# Check if hovering can start (can be overridden by subclasses)
func _can_start_hovering() -> bool:
	return true


func _on_mouse_enter() -> void:
	if can_be_interacted_with and _can_start_hovering():
		change_state(DraggableState.HOVERING)


func _on_mouse_exit() -> void:
	match current_state:
		DraggableState.HOVERING:
			change_state(DraggableState.IDLE)


func _on_gui_input(event: InputEvent) -> void:
	if not can_be_interacted_with:
		return
	
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)


func move(target_destination: Vector2, degree: float) -> void:
	# Skip if current position and rotation match target
	if global_position == target_destination and rotation == degree:
		return

	# Force transition to MOVING state (highest priority)
	change_state(DraggableState.MOVING)

	# Stop existing movement
	if move_tween and move_tween.is_valid():
		move_tween.kill()
	
	# Store target position and rotation for original value preservation
	self.target_destination = target_destination
	self.target_rotation = degree
	
	# Initial setup
	rotation = 0
	destination_degree = degree
	is_moving_to_destination = true
	
	# Smooth Tween-based movement with dynamic duration based on moving_speed
	var distance = global_position.distance_to(target_destination)
	var duration = distance / moving_speed
	
	move_tween = create_tween()
	move_tween.tween_property(self, "global_position", target_destination, duration)
	move_tween.tween_callback(_finish_move)






func _handle_mouse_button(mouse_event: InputEventMouseButton) -> void:
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	
	# Ignore all input during MOVING state
	if current_state == DraggableState.MOVING:
		return
	
	if mouse_event.is_pressed():
		_handle_mouse_pressed()
	
	if mouse_event.is_released():
		_handle_mouse_released()


func _handle_mouse_pressed() -> void:
	is_pressed = true
	match current_state:
		DraggableState.HOVERING:
			change_state(DraggableState.HOLDING)


func _handle_mouse_released() -> void:
	is_pressed = false
	match current_state:
		DraggableState.HOLDING:
			change_state(DraggableState.IDLE)
