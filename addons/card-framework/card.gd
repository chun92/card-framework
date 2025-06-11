class_name Card
extends DraggableObject


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


var card_info: Dictionary
var card_container: CardContainer


@onready var front_face_texture: TextureRect = $FrontFace/TextureRect
@onready var back_face_texture: TextureRect = $BackFace/TextureRect


func _ready():
	super._ready()
	front_face_texture.size = card_size
	back_face_texture.size = card_size
	if front_image:
		front_face_texture.texture = front_image
	if back_image:
		back_face_texture.texture = back_image
	pivot_offset = card_size / 2


func _on_move_done() -> void:
	card_container.on_card_move_done(self)


func _on_mouse_enter() -> void:
	if hovering_card_count == 0:
		super._on_mouse_enter()


func set_faces(front_face: Texture2D, back_face: Texture2D) -> void:
	front_face_texture.texture = front_face
	back_face_texture.texture = back_face


func return_card() -> void:
	rotation = 0
	is_moving_to_destination = true


func start_hovering() -> void:
	if not is_hovering:
		hovering_card_count += 1
		super.start_hovering()


func end_hovering(restore_object_position: bool) -> void:
	if is_hovering:
		hovering_card_count -= 1
		super.end_hovering(restore_object_position)


func set_holding() -> void:
	super.set_holding()
	if card_container:
		card_container.hold_card(self)


func get_string() -> String:
	return card_name


func _handle_mouse_pressed() -> void:
	card_container.on_card_pressed(self)
	super._handle_mouse_pressed()


func _handle_mouse_released() -> void:
	super._handle_mouse_released()
	if card_container:
		card_container.release_holding_cards()
