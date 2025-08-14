## A stacked card container with directional positioning and interaction controls.
##
## Pile provides a traditional card stack implementation where cards are arranged
## in a specific direction with configurable spacing. It supports various interaction
## modes from full movement to top-card-only access, making it suitable for deck
## implementations, foundation piles, and discard stacks.
##
## Key Features:
## - Directional stacking (up, down, left, right)
## - Configurable stack display limits and spacing
## - Flexible interaction controls (all cards, top only, none)
## - Dynamic drop zone positioning following top card
## - Visual depth management with z-index layering
##
## Common Use Cases:
## - Foundation piles in Solitaire games
## - Draw/discard decks with face-down cards
## - Tableau piles with partial card access
##
## Usage:
## [codeblock]
## @onready var deck = $Deck
## deck.layout = Pile.PileDirection.DOWN
## deck.card_face_up = false
## deck.restrict_to_top_card = true
## [/codeblock]
class_name Pile
extends CardContainer

# Enums
## Defines the stacking direction for cards in the pile.
enum PileDirection {
	UP,    ## Cards stack upward (negative Y direction)
	DOWN,  ## Cards stack downward (positive Y direction) 
	LEFT,  ## Cards stack leftward (negative X direction)
	RIGHT  ## Cards stack rightward (positive X direction)
}

@export_group("pile_layout")
## Distance between each card in the stack display
@export var stack_display_gap := CardFrameworkSettings.LAYOUT_STACK_GAP
## Maximum number of cards to visually display in the pile
## Cards beyond this limit will be hidden under the visible stack
@export var max_stack_display := CardFrameworkSettings.LAYOUT_MAX_STACK_DISPLAY
## Whether cards in the pile show their front face (true) or back face (false)
@export var card_face_up := true
## Direction in which cards are stacked from the pile's base position
@export var layout := PileDirection.UP

@export_group("pile_interaction")
## Whether any card in the pile can be moved via drag-and-drop
@export var allow_card_movement: bool = true
## Restricts movement to only the top card (requires allow_card_movement = true)
@export var restrict_to_top_card: bool = true
## Whether drop zone follows the top card position (requires allow_card_movement = true)
@export var align_drop_zone_with_top_card := true


## Returns the top n cards from the pile without removing them.
## Cards are returned in top-to-bottom order (most recent first).
## @param n: Number of cards to retrieve from the top
## @returns: Array of cards from the top of the pile (limited by available cards)
func get_top_cards(n: int) -> Array:
	var arr_size = _held_cards.size()
	if n > arr_size:
		n = arr_size
	
	var result = []
	
	for i in range(n):
		result.append(_held_cards[arr_size - 1 - i])
	
	return result


## Updates z-index values for all cards to maintain proper layering.
## Pressed cards receive elevated z-index to appear above the pile.
func _update_target_z_index() -> void:
	for i in range(_held_cards.size()):
		var card = _held_cards[i]
		if card.is_pressed:
			card.stored_z_index = CardFrameworkSettings.VISUAL_PILE_Z_INDEX + i
		else:
			card.stored_z_index = i


## Updates visual positions and interaction states for all cards in the pile.
## Positions cards according to layout direction and applies interaction restrictions.
func _update_target_positions() -> void:
	# Calculate top card position for drop zone alignment
	var last_index = _held_cards.size() - 1
	if last_index < 0:
		last_index = 0
	var last_offset = _calculate_offset(last_index)
	
	# Align drop zone with top card if enabled
	if enable_drop_zone and align_drop_zone_with_top_card:
		drop_zone.change_sensor_position_with_offset(last_offset)

	# Position each card and set interaction state
	for i in range(_held_cards.size()):
		var card = _held_cards[i]
		var offset = _calculate_offset(i)
		var target_pos = position + offset
		
		# Set card appearance and position
		card.show_front = card_face_up
		card.move(target_pos, 0)
		
		# Apply interaction restrictions
		if not allow_card_movement: 
			card.can_be_interacted_with = false
		elif restrict_to_top_card:
			if i == _held_cards.size() - 1:
				card.can_be_interacted_with = true
			else:
				card.can_be_interacted_with = false


## Calculates the visual offset for a card at the given index in the stack.
## Respects max_stack_display limit to prevent excessive visual spreading.
## @param index: Position of the card in the stack (0 = bottom, higher = top)
## @returns: Vector2 offset from the pile's base position
func _calculate_offset(index: int) -> Vector2:
	# Clamp to maximum display limit to prevent visual overflow
	var actual_index = min(index, max_stack_display - 1)
	var offset_value = actual_index * stack_display_gap
	var offset = Vector2()

	# Apply directional offset based on pile layout
	match layout:
		PileDirection.UP:
			offset.y -= offset_value  # Stack upward (negative Y)
		PileDirection.DOWN:
			offset.y += offset_value  # Stack downward (positive Y)
		PileDirection.RIGHT:
			offset.x += offset_value  # Stack rightward (positive X)
		PileDirection.LEFT:
			offset.x -= offset_value  # Stack leftward (negative X)

	return offset
