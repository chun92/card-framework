## A draggable object that supports mouse interaction with state-based animation system.
##
## This class provides a robust state machine for handling mouse interactions including
## hover effects, drag operations, and programmatic movement using Tween animations.
## All interactive cards and objects extend this base class to inherit consistent
## drag-and-drop behavior.
##
## Key Features:
## - State machine with safe transitions (IDLE → HOVERING → HOLDING → MOVING)
## - Tween-based animations for smooth hover effects and movement
## - Mouse interaction handling with proper event management
## - Z-index management for visual layering during interactions
## - Extensible design with virtual methods for customization
##
## State Transitions:
## - IDLE: Default state, ready for interaction
## - HOVERING: Mouse over with visual feedback (scale, rotation, position)
## - HOLDING: Active drag state following mouse movement
## - MOVING: Programmatic movement ignoring user input
##
## Usage:
## [codeblock]
## class_name MyDraggable
## extends DraggableObject
##
## func _can_start_hovering() -> bool:
##     return my_custom_condition
## [/codeblock]
class_name DraggableObject
extends Control

# Enums
## Enumeration of possible interaction states for the draggable object.
enum DraggableState {
	IDLE,       ## Default state - no interaction
	HOVERING,   ## Mouse over state - visual feedback
	HOLDING,    ## Dragging state - follows mouse
	MOVING      ## Programmatic move state - ignores input
}

## The speed at which the objects moves.
@export var moving_speed: int = CardFrameworkSettings.ANIMATION_MOVE_SPEED
## Whether the object can be interacted with.
@export var can_be_interacted_with: bool = true
## The distance the object hovers when interacted with.
@export var hover_distance: int = CardFrameworkSettings.PHYSICS_HOVER_DISTANCE
## The scale multiplier when hovering.
@export var hover_scale: float = CardFrameworkSettings.ANIMATION_HOVER_SCALE
## The rotation in degrees when hovering.
@export var hover_rotation: float = CardFrameworkSettings.ANIMATION_HOVER_ROTATION
## The duration for hover animations.
@export var hover_duration: float = CardFrameworkSettings.ANIMATION_HOVER_DURATION


# Legacy variables - kept for compatibility but no longer used in state machine
var is_pressed: bool = false
var is_holding: bool = false
var stored_z_index: int:
	set(value):
		z_index = value
		stored_z_index = value
# State Machine
var current_state: DraggableState = DraggableState.IDLE

# Mouse tracking
var is_mouse_inside: bool = false

# Movement state tracking
var is_moving_to_destination: bool = false
var is_returning_to_original: bool = false

# Position and animation tracking
var current_holding_mouse_position: Vector2
var original_position: Vector2
var original_scale: Vector2
var original_hover_rotation: float
var current_hover_position: Vector2  # Track position during hover animation

# Move operation tracking
var target_destination: Vector2  # Target position passed to move() function
var target_rotation: float       # Target rotation passed to move() function
var original_destination: Vector2
var original_rotation: float
var destination_degree: float

# Tween objects
var move_tween: Tween
var hover_tween: Tween

# State transition rules
var allowed_transitions = {
	DraggableState.IDLE: [DraggableState.HOVERING, DraggableState.HOLDING, DraggableState.MOVING],
	DraggableState.HOVERING: [DraggableState.IDLE, DraggableState.HOLDING, DraggableState.MOVING],
	DraggableState.HOLDING: [DraggableState.IDLE, DraggableState.MOVING],
	DraggableState.MOVING: [DraggableState.IDLE]
}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	connect("mouse_entered", _on_mouse_enter)
	connect("mouse_exited", _on_mouse_exit)
	connect("gui_input", _on_gui_input)
	
	original_destination = global_position
	original_rotation = rotation
	original_position = position
	original_scale = scale
	original_hover_rotation = rotation
	stored_z_index = z_index


## Safely transitions between interaction states using predefined rules.
## Validates transitions and handles state cleanup/initialization automatically.
## @param new_state: Target state to transition to
## @returns: True if transition was successful, false if invalid/blocked
func change_state(new_state: DraggableState) -> bool:
	if new_state == current_state:
		return true
	
	# Validate transition is allowed by state machine rules
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
			z_index = stored_z_index + CardFrameworkSettings.VISUAL_DRAG_Z_OFFSET
			_start_hover_animation()
			
		DraggableState.HOLDING:
			# Preserve hover position if transitioning from HOVERING state
			if from_state == DraggableState.HOVERING:
				_preserve_hover_position()
			# For IDLE → HOLDING transitions, current position is maintained
			
			current_holding_mouse_position = get_local_mouse_position()
			z_index = stored_z_index + CardFrameworkSettings.VISUAL_DRAG_Z_OFFSET
			rotation = 0
			
		DraggableState.MOVING:
			# Stop hover animations and ignore input during programmatic movement
			if hover_tween and hover_tween.is_valid():
				hover_tween.kill()
				hover_tween = null
			z_index = stored_z_index + CardFrameworkSettings.VISUAL_DRAG_Z_OFFSET
			mouse_filter = Control.MOUSE_FILTER_IGNORE


# Handle state exit
func _exit_state(state: DraggableState) -> void:
	match state:
		DraggableState.HOVERING:
			z_index = stored_z_index
			_stop_hover_animation()
			
		DraggableState.HOLDING:
			z_index = stored_z_index
			# Reset visual effects but preserve position for return_card() animation
			scale = original_scale
			rotation = original_hover_rotation
			
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


# Start hover animation with tween
func _start_hover_animation() -> void:
	# Stop any existing hover animation
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
		position = original_position  # Reset position to original before starting new hover
		scale = original_scale
		rotation = original_hover_rotation

	# Update original position to current position (important for correct return)
	original_position = position
	original_scale = scale
	original_hover_rotation = rotation
	
	# Store current position before animation
	current_hover_position = position
	
	# Create new hover tween
	hover_tween = create_tween()
	hover_tween.set_parallel(true)  # Allow multiple properties to animate simultaneously
	
	# Animate position (hover up)
	var target_position = Vector2(position.x, position.y - hover_distance)
	hover_tween.tween_property(self, "position", target_position, hover_duration)
	
	# Animate scale
	hover_tween.tween_property(self, "scale", original_scale * hover_scale, hover_duration)
	
	# Animate rotation
	hover_tween.tween_property(self, "rotation", deg_to_rad(hover_rotation), hover_duration)
	
	# Update current hover position tracking
	hover_tween.tween_method(_update_hover_position, position, target_position, hover_duration)


# Stop hover animation and return to original state
func _stop_hover_animation() -> void:
	# Stop any existing hover animation
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
	# Create new tween to return to original state
	hover_tween = create_tween()
	hover_tween.set_parallel(true)
	
	# Animate back to original position
	hover_tween.tween_property(self, "position", original_position, hover_duration)
	
	# Animate back to original scale
	hover_tween.tween_property(self, "scale", original_scale, hover_duration)
	
	# Animate back to original rotation
	hover_tween.tween_property(self, "rotation", original_hover_rotation, hover_duration)
	
	# Update current hover position tracking
	hover_tween.tween_method(_update_hover_position, position, original_position, hover_duration)


# Track current position during hover animation for smooth HOLDING transition
func _update_hover_position(pos: Vector2) -> void:
	current_hover_position = pos


# Preserve current hover position when transitioning to HOLDING
func _preserve_hover_position() -> void:
	# Stop hover animation and preserve current position
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		hover_tween = null
	
	# Explicitly set position to current hover position
	# This ensures smooth transition from hover animation to holding
	position = current_hover_position


## Virtual method to determine if hovering animation can start.
## Override in subclasses to implement custom hovering conditions.
## @returns: True if hovering is allowed, false otherwise
func _can_start_hovering() -> bool:
	return true


func _on_mouse_enter() -> void:
	is_mouse_inside = true
	if can_be_interacted_with and _can_start_hovering():
		change_state(DraggableState.HOVERING)


func _on_mouse_exit() -> void:
	is_mouse_inside = false
	match current_state:
		DraggableState.HOVERING:
			change_state(DraggableState.IDLE)


func _on_gui_input(event: InputEvent) -> void:
	if not can_be_interacted_with:
		return
	
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)


## Moves the object to target position with optional rotation using smooth animation.
## Automatically transitions to MOVING state and handles animation timing based on distance.
## @param target_destination: Global position to move to
## @param degree: Target rotation in radians
func move(target_destination: Vector2, degree: float) -> void:
	# Skip if current position and rotation match target
	if global_position == target_destination and rotation == degree:
		return

	# Force transition to MOVING state (highest priority)
	change_state(DraggableState.MOVING)

	# Stop existing movement
	if move_tween and move_tween.is_valid():
		move_tween.kill()
		move_tween = null
	
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


## Returns the object to its original position with smooth animation.
func return_to_original() -> void:
	is_returning_to_original = true
	move(original_destination, original_rotation)


func _handle_mouse_pressed() -> void:
	is_pressed = true
	match current_state:
		DraggableState.HOVERING:
			change_state(DraggableState.HOLDING)
		DraggableState.IDLE:
			if is_mouse_inside and can_be_interacted_with and _can_start_hovering():
				change_state(DraggableState.HOLDING)


func _handle_mouse_released() -> void:
	is_pressed = false
	match current_state:
		DraggableState.HOLDING:
			change_state(DraggableState.IDLE)
