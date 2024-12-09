class_name Card
extends Control

const HOLDING_Z_INDEX = 1000

@export var card_name: String
@export var card_size := Vector2(150, 210)
@export var front_image: Texture2D
@export var back_image: Texture2D
@export var show_front := true : 
	set(value):
		if value:
			front_face_texture.visible = true
			back_face_texture.visible = false
		else:
			front_face_texture.visible = false
			back_face_texture.visible = true

@export var return_speed := 200
@export var can_be_interact_with := true
@export var hover_distance := 10

var card_info: Dictionary

var is_hovering := false
var is_clicked := false
var is_holding := false
var stored_z_index: int :
	set(value):
		z_index = value
		stored_z_index = value
var is_moving_to_destination := false
var current_holding_mouse_position: Vector2
var destination: Vector2
var destination_degree: float
var target_drop_zone: DropZone

static var is_any_card_hovering := false

@onready var front_face_texture := $FrontFace/TextureRect
@onready var back_face_texture := $BackFace/TextureRect


func _ready():	
	mouse_filter = Control.MOUSE_FILTER_STOP
	connect("mouse_entered", _on_mouse_enter)
	connect("mouse_exited", _on_mouse_exited)
	connect("gui_input", _on_gui_input)
	
	CardFrameworkSignalBus.drag_dropped.connect(_on_drag_dropped)
	CardFrameworkSignalBus.card_move_done.connect(_on_card_move_done)
	
	front_face_texture.size = card_size
	back_face_texture.size = card_size
	if front_image:
		front_face_texture.texture = front_image
	if back_image:
		back_face_texture.texture = back_image
	pivot_offset = card_size / 2
	destination = global_position
	show_front = show_front
	stored_z_index = z_index

func _process(delta):
	if is_holding:
		start_hovering()
		global_position = get_global_mouse_position() - current_holding_mouse_position
		
	if is_moving_to_destination:
		z_index = stored_z_index + HOLDING_Z_INDEX
		global_position = global_position.move_toward(destination, return_speed * delta)
		if global_position.distance_to(destination) < 0.001:
			global_position = destination
			is_moving_to_destination = false
			end_hovering(false)
			z_index = stored_z_index
			CardFrameworkSignalBus.card_move_done.emit(self)
			rotation = destination_degree
			if target_drop_zone != null:
				CardFrameworkSignalBus.card_dropped.emit(self, target_drop_zone)
				target_drop_zone = null


func set_faces(front_face: Texture2D, back_face: Texture2D):
	front_face_texture.texture = front_face
	back_face_texture.texture = back_face
	

func return_card():
	rotation = 0
	is_moving_to_destination = true


func move(target_destination: Vector2):
	rotation = 0
	is_moving_to_destination = true
	self.destination = target_destination

	
func move_to_drop_zone(drop_zone: DropZone):
	rotation = 0
	is_moving_to_destination = true
	destination = drop_zone.get_place_zone()
	target_drop_zone = drop_zone


func move_rotation(degree: float):
	destination_degree = degree


func start_hovering():
	if not is_hovering:
		is_hovering = true
		is_any_card_hovering = true
		z_index = stored_z_index + HOLDING_Z_INDEX
		position.y -= hover_distance


func end_hovering(restore_card_position: bool):
	if is_hovering:
		z_index = stored_z_index
		is_hovering = false
		is_any_card_hovering = false
		if restore_card_position:
			position.y += hover_distance


func set_holding():
	is_holding = true
	current_holding_mouse_position = get_local_mouse_position()
	z_index = stored_z_index + HOLDING_Z_INDEX
	rotation = 0


func set_releasing(itself_dropped: bool):
	if is_holding:
		CardFrameworkSignalBus.drag_dropped.emit(self, itself_dropped)
	is_holding = false


func get_string():
	return card_name


func _on_mouse_enter():
	if !is_any_card_hovering and !is_moving_to_destination and can_be_interact_with:
		start_hovering()


func _on_mouse_exited():
	if is_clicked:
		return
	end_hovering(true)


func _on_gui_input(event: InputEvent):
	if !can_be_interact_with:
		return false
		
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		
		if mouse_event.is_pressed():
			is_clicked = true
			CardFrameworkSignalBus.card_clicked.emit(self)
			set_holding()
		
		if mouse_event.is_released():
			is_clicked = false
			CardFrameworkSignalBus.card_released.emit(self)
			set_releasing(true)


func _on_drag_dropped(_card: Card, _itself_dropped: bool):
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _on_card_move_done(_card: Card):
	mouse_filter = Control.MOUSE_FILTER_STOP
