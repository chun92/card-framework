## A card object that represents a single playing card with drag-and-drop functionality.
##
## The Card class extends DraggableObject to provide interactive card behavior including
## hover effects, drag operations, and visual state management. Cards can display
## different faces (front/back) and integrate with the card framework's container system.
##
## Key Features:
## - Visual state management (front/back face display)
## - Drag-and-drop interaction with state machine
## - Integration with CardContainer for organized card management
## - Hover animation and visual feedback
##
## Usage:
## [codeblock]
## var card = card_factory.create_card("ace_spades", target_container)
## card.show_front = true
## card.move(target_position, 0)
## [/codeblock]
class_name Card
extends DraggableObject

# Static counters for global card state tracking
static var hovering_card_count: int = 0
static var holding_card_count: int = 0


## The name of the card.
@export var card_name: String
## The size of the card.
@export var card_size: Vector2 = CardFrameworkSettings.LAYOUT_DEFAULT_CARD_SIZE
## The texture for the front face of the card.
@export var front_image: Texture2D
## The texture for the back face of the card.
@export var back_image: Texture2D
## Whether the front face of the card is shown.
## If true, the front face is visible; otherwise, the back face is visible.
@export var show_front: bool = true:
	set(value):
		_show_front = value
		_update_face_visibility()
	get:
		return _show_front
## The TextureRect node for displaying the front face of the card.
## If not assigned, will fallback to $FrontFace/TextureRect for backward compatibility.
@export var front_face_texture: TextureRect
## The TextureRect node for displaying the back face of the card.
## If not assigned, will fallback to $BackFace/TextureRect for backward compatibility.
@export var back_face_texture: TextureRect


# Card data and container reference
var card_info: Dictionary
var card_container: CardContainer
var _show_front: bool = true


func _ready() -> void:
	super._ready()

	# Fallback to hardcoded paths if not assigned (backward compatibility)
	if front_face_texture == null:
		front_face_texture = $FrontFace/TextureRect if has_node("FrontFace/TextureRect") else null
	if back_face_texture == null:
		back_face_texture = $BackFace/TextureRect if has_node("BackFace/TextureRect") else null

	# Verify required nodes are available
	if front_face_texture == null or back_face_texture == null:
		push_error("Card requires front_face_texture and back_face_texture to be assigned or FrontFace/TextureRect and BackFace/TextureRect nodes to exist")
		return

	front_face_texture.size = card_size
	back_face_texture.size = card_size
	if front_image:
		front_face_texture.texture = front_image
	if back_image:
		back_face_texture.texture = back_image
	pivot_offset = card_size / 2

	# Apply deferred face visibility update
	_update_face_visibility()


## Updates the visibility of front and back face textures based on show_front value.
## Safe to call before @onready variables are initialized.
func _update_face_visibility() -> void:
	# Only apply if texture nodes are ready
	if front_face_texture != null and back_face_texture != null:
		if _show_front:
			front_face_texture.visible = true
			back_face_texture.visible = false
		else:
			front_face_texture.visible = false
			back_face_texture.visible = true


func _on_move_done() -> void:
	card_container.on_card_move_done(self)


## Sets the front and back face textures for this card.
##
## @param front_face: The texture to use for the front face
## @param back_face: The texture to use for the back face
func set_faces(front_face: Texture2D, back_face: Texture2D) -> void:
	front_face_texture.texture = front_face
	back_face_texture.texture = back_face


## Returns the card to its original position with smooth animation.
func return_card() -> void:
	super.return_to_original()


# Override state entry to add card-specific logic
func _enter_state(state: DraggableState, from_state: DraggableState) -> void:
	super._enter_state(state, from_state)
	
	match state:
		DraggableState.HOVERING:
			hovering_card_count += 1
		DraggableState.HOLDING:
			holding_card_count += 1
			if card_container:
				card_container.hold_card(self)

# Override state exit to add card-specific logic
func _exit_state(state: DraggableState) -> void:
	match state:
		DraggableState.HOVERING:
			hovering_card_count -= 1
		DraggableState.HOLDING:
			holding_card_count -= 1
	
	super._exit_state(state)

## Legacy compatibility method for holding state.
## @deprecated Use state machine transitions instead
func set_holding() -> void:
	if card_container:
		card_container.hold_card(self)


## Returns a string representation of this card.
func get_string() -> String:
	return card_name


## Checks if this card can start hovering based on global card state.
## Prevents multiple cards from hovering simultaneously.
func _can_start_hovering() -> bool:
	return hovering_card_count == 0 and holding_card_count == 0


## Handles mouse press events with container notification.
func _handle_mouse_pressed() -> void:
	card_container.on_card_pressed(self)
	super._handle_mouse_pressed()


## Handles mouse release events and releases held cards.
func _handle_mouse_released() -> void:
	super._handle_mouse_released()
	if card_container:
		card_container.release_holding_cards()
