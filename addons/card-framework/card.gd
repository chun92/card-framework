class_name Card
extends Control


const Z_INDEX_OFFSET_WHEN_HOLDING = 1000


static var hovering_card_count: int = 0


## The name of the card.
@export var card_name: String
## The size of the card.
@export var card_size: Vector2 = Vector2(150, 210)
## The texture for the front face of the card.
@export var front_image: Texture2D
## The texture for the back face of the card.
@export var back_image: Texture2D
## Whether the front face of the card is shown.
## If true, the front face is visible; otherwise, the back face is visible.
@export var show_front: bool = true:
	set(value):
		if value:
			front_face_texture.visible = true
			back_face_texture.visible = false
		else:
			front_face_texture.visible = false
			back_face_texture.visible = true
## The speed at which the card moves.
@export var moving_speed: int = 2000
## Whether the card can be interacted with.
@export var can_be_interacted_with: bool = true
## The distance the card hovers when interacted with.
@export var hover_distance: int = 10


var card_info: Dictionary
var card_container: CardContainer
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
var target_container: CardContainer


@onready var front_face_texture: TextureRect = $FrontFace/TextureRect
@onready var back_face_texture: TextureRect = $BackFace/TextureRect


func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	connect("mouse_entered", _on_mouse_enter)
	connect("mouse_exited", _on_mouse_exit)
	connect("gui_input", _on_gui_input)
	
	front_face_texture.size = card_size
	back_face_texture.size = card_size
	if front_image:
		front_face_texture.texture = front_image
	if back_image:
		back_face_texture.texture = back_image
	pivot_offset = card_size / 2
	destination = global_position
	stored_z_index = z_index


func _process(delta: float) -> void:
	if is_holding:
		start_hovering()
		global_position = get_global_mouse_position() - current_holding_mouse_position
		
	if is_moving_to_destination:
		_set_destination()

		var new_position = position.move_toward(destination_as_local, moving_speed * delta)

		# card move done
		if position.distance_to(new_position) < 0.01 or position.distance_to(destination_as_local) < 0.01:
			position = destination_as_local
			is_moving_to_destination = false
			end_hovering(false)
			z_index = stored_z_index
			rotation = destination_degree
			mouse_filter = Control.MOUSE_FILTER_STOP
			card_container.on_card_move_done(self)
			target_container = null
		else:
			position = new_position


func _on_mouse_enter() -> void:
	if hovering_card_count == 0 and not is_moving_to_destination and can_be_interacted_with:
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


func set_faces(front_face: Texture2D, back_face: Texture2D) -> void:
	front_face_texture.texture = front_face
	back_face_texture.texture = back_face


func return_card() -> void:
	rotation = 0
	is_moving_to_destination = true


func move(target_destination: Vector2, degree: float) -> void:
	rotation = 0
	destination_degree = degree
	is_moving_to_destination = true
	self.destination = target_destination


func start_hovering() -> void:
	if not is_hovering:
		is_hovering = true
		hovering_card_count += 1
		z_index += Z_INDEX_OFFSET_WHEN_HOLDING
		position.y -= hover_distance


func end_hovering(restore_card_position: bool) -> void:
	if is_hovering:
		z_index = stored_z_index
		is_hovering = false
		hovering_card_count -= 1
		if restore_card_position:
			position.y += hover_distance


func set_holding() -> void:
	is_holding = true
	current_holding_mouse_position = get_local_mouse_position()
	z_index = stored_z_index + Z_INDEX_OFFSET_WHEN_HOLDING
	rotation = 0
	if card_container:
		card_container.hold_card(self)


func set_releasing() -> void:
	is_holding = false


func get_string() -> String:
	return card_name


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
	card_container.on_card_pressed(self)
	set_holding()


func _handle_mouse_released() -> void:
	is_pressed = false
	if card_container:
		card_container.release_holding_cards()


func _set_destination() -> void:
	var t = get_global_transform().affine_inverse()
	var local_position = (t.x * destination.x) + (t.y * destination.y) + t.origin
	destination_as_local = local_position + position
	z_index = stored_z_index + Z_INDEX_OFFSET_WHEN_HOLDING
