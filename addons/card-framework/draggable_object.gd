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
var destination: Vector2
var destination_as_local: Vector2
var destination_degree: float


func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	connect("mouse_entered", _on_mouse_enter)
	connect("mouse_exited", _on_mouse_exit)
	connect("gui_input", _on_gui_input)
	
	destination = global_position
	stored_z_index = z_index


func _process(delta: float) -> void:
	if is_holding:
		start_hovering()
		global_position = get_global_mouse_position() - current_holding_mouse_position
		
	if is_moving_to_destination:
		_set_destination()

		var new_position = position.move_toward(destination_as_local, moving_speed * delta)

		# object move done
		if position.distance_to(new_position) < 0.01 or position.distance_to(destination_as_local) < 0.01:
			position = destination_as_local
			is_moving_to_destination = false
			end_hovering(false)
			z_index = stored_z_index
			rotation = destination_degree
			mouse_filter = Control.MOUSE_FILTER_STOP
			_on_move_done()
		else:
			position = new_position


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
	rotation = 0
	destination_degree = degree
	is_moving_to_destination = true
	self.destination = target_destination


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


func _set_destination() -> void:
	var t = get_global_transform().affine_inverse()
	var local_position = (t.x * destination.x) + (t.y * destination.y) + t.origin
	destination_as_local = local_position + position
	z_index = stored_z_index + Z_INDEX_OFFSET_WHEN_HOLDING
