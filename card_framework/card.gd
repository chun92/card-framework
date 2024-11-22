class_name Card
extends Control

const HOLDING_Z_INDEX = 1000

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

@export var return_speed := 2000

var is_hovering := false
var is_clicked := false
var is_holding := false
var stored_z_index: int
var is_moving_to_destination := false
var current_holding_mouse_position: Vector2
var destination: Vector2
var target_drop_zone: DropZone

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
		
	destination = global_position
	show_front = show_front
	stored_z_index = z_index


func _process(delta):
	if is_holding:
		global_position = get_global_mouse_position() - current_holding_mouse_position
		
	if is_moving_to_destination:
		global_position = global_position.move_toward(destination, return_speed * delta)
		if global_position == destination:
			is_moving_to_destination = false
			z_index = stored_z_index
			CardFrameworkSignalBus.card_move_done.emit(self)
			if target_drop_zone != null:
				CardFrameworkSignalBus.card_dropped.emit(self, target_drop_zone)
				target_drop_zone = null


func return_card():
	is_moving_to_destination = true


func move(destination: Vector2):
	is_moving_to_destination = true
	self.destination = destination

	
func move_to_drop_zone(drop_zone: DropZone):
	is_moving_to_destination = true
	destination = drop_zone.get_place_zone()
	target_drop_zone = drop_zone

	
func _on_mouse_enter():
	if _can_interact_with():
		is_hovering = true
	
	
func _on_mouse_exited():
	if _can_interact_with():
		is_hovering = false


func _on_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		
		if mouse_event.pressed:
			is_clicked = true
			is_holding = true
			current_holding_mouse_position = get_local_mouse_position()
			z_index = HOLDING_Z_INDEX
		else:
			if is_holding:
				CardFrameworkSignalBus.drag_dropped.emit(self)
			is_clicked = false
			is_holding = false


func _can_interact_with() -> bool:
	return true


func _on_drag_dropped(_card: Card):
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	
func _on_card_move_done(_card: Card):
	mouse_filter = Control.MOUSE_FILTER_STOP
