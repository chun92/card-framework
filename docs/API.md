# Card Framework API Reference

Complete API reference for the Godot 4.x Card Framework addon. This framework provides a modular system for creating 2D card games with drag-and-drop functionality, flexible container management, and extensible card factories.

## Table of Contents

- [Configuration](#configuration)
  - [CardFrameworkSettings](#cardframeworksettings)
- [Core Classes](#core-classes)
  - [CardManager](#cardmanager)
  - [Card](#card)  
  - [CardContainer](#cardcontainer)
  - [CardFactory](#cardfactory)
  - [JsonCardFactory](#jsoncardfactory)
- [Specialized Containers](#specialized-containers)
  - [Pile](#pile)
  - [Hand](#hand)
- [Supporting Classes](#supporting-classes)
  - [DraggableObject](#draggableobject)
  - [DropZone](#dropzone)
  - [HistoryElement](#historyelement)

---

## Configuration

### CardFrameworkSettings

**Extends:** `RefCounted`

Centralized configuration constants for all Card Framework components. This class provides consistent default values without requiring Autoload, allowing components to reference framework-wide constants directly.

#### Animation Constants

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `ANIMATION_MOVE_SPEED` | `float` | `2000.0` | Speed of card movement animations in pixels per second |
| `ANIMATION_HOVER_DURATION` | `float` | `0.10` | Duration of hover animations in seconds |
| `ANIMATION_HOVER_SCALE` | `float` | `1.1` | Scale multiplier applied during hover effects |
| `ANIMATION_HOVER_ROTATION` | `float` | `0.0` | Rotation in degrees applied during hover effects |

#### Physics Constants

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `PHYSICS_HOVER_DISTANCE` | `float` | `10.0` | Distance threshold for hover detection in pixels |
| `PHYSICS_CARD_HOVER_DISTANCE` | `float` | `30.0` | Distance cards move up during hover in pixels |

#### Visual Layout Constants

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `VISUAL_DRAG_Z_OFFSET` | `int` | `1000` | Z-index offset applied to cards during drag operations |
| `VISUAL_PILE_Z_INDEX` | `int` | `3000` | Z-index for pile cards to ensure proper layering |
| `VISUAL_SENSOR_Z_INDEX` | `int` | `-1000` | Z-index for drop zone sensors (below everything) |
| `VISUAL_OUTLINE_Z_INDEX` | `int` | `1200` | Z-index for debug outlines (above UI) |

#### Container Layout Constants

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `LAYOUT_DEFAULT_CARD_SIZE` | `Vector2` | `Vector2(150, 210)` | Default card size used throughout the framework |
| `LAYOUT_STACK_GAP` | `int` | `8` | Distance between stacked cards in piles |
| `LAYOUT_MAX_STACK_DISPLAY` | `int` | `6` | Maximum cards to display in stack before hiding |
| `LAYOUT_MAX_HAND_SIZE` | `int` | `10` | Maximum number of cards in hand containers |
| `LAYOUT_MAX_HAND_SPREAD` | `int` | `700` | Maximum pixel spread for hand arrangements |

#### Debug Constants

| Constant | Type | Value | Description |
|----------|------|-------|-------------|
| `DEBUG_OUTLINE_COLOR` | `Color` | `Color(1, 0, 0, 1)` | Color used for sensor outlines and debug indicators |

#### Usage

```gdscript
# Reference constants directly in component @export variables
@export var moving_speed: int = CardFrameworkSettings.ANIMATION_MOVE_SPEED
@export var hover_distance: int = CardFrameworkSettings.PHYSICS_HOVER_DISTANCE

# Or use in code
z_index = stored_z_index + CardFrameworkSettings.VISUAL_DRAG_Z_OFFSET
```

---

## Core Classes

### CardManager

**Extends:** `Control`

The central orchestrator for all card game operations. Manages card containers, handles drag-and-drop operations, and maintains game history for undo functionality.

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `card_size` | `Vector2` | `Vector2(150, 210)` | Default size for all cards in the game |
| `card_factory_scene` | `PackedScene` | - | Scene containing the CardFactory implementation |
| `debug_mode` | `bool` | `false` | Enables visual debugging for drop zones |

#### Methods

##### undo() -> void
Undoes the last card movement operation by restoring cards to their previous container.

```gdscript
card_manager.undo()
```

##### reset_history() -> void
Clears all stored history elements, preventing further undo operations.

```gdscript
card_manager.reset_history()
```

#### Internal Methods

These methods are called automatically by the framework:

- `_add_card_container(id: int, card_container: CardContainer)` - Registers a container
- `_delete_card_container(id: int)` - Unregisters a container
- `_on_drag_dropped(cards: Array)` - Handles completed drag operations
- `_add_history(to: CardContainer, cards: Array)` - Records movement for undo

---

### Card

**Extends:** `DraggableObject`

Represents an individual playing card with front/back faces and interaction capabilities.

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `card_name` | `String` | `""` | Unique identifier for the card |
| `card_size` | `Vector2` | `Vector2(150, 210)` | Dimensions of the card |
| `front_image` | `Texture2D` | - | Texture for card front face |
| `back_image` | `Texture2D` | - | Texture for card back face |
| `show_front` | `bool` | `true` | Whether front face is visible |

#### Variables

| Variable | Type | Description |
|----------|------|-------------|
| `card_info` | `Dictionary` | Additional card data from JSON |
| `card_container` | `CardContainer` | Container currently holding this card |

#### Methods

##### set_faces(front_face: Texture2D, back_face: Texture2D) -> void
Sets both front and back textures for the card.

```gdscript
card.set_faces(front_texture, back_texture)
```

##### return_card() -> void
Returns card to its original position with no rotation.

```gdscript
card.return_card()
```

##### start_hovering() -> void
Initiates hover effect, raising card visually and adjusting global hover count.

```gdscript
card.start_hovering()
```

##### end_hovering(restore_object_position: bool) -> void
Ends hover effect and optionally restores position.

```gdscript
card.end_hovering(true)  # Restore position
card.end_hovering(false) # Keep current position
```

##### set_holding() -> void
*[Deprecated]* Legacy method for setting holding state. Use state machine transitions instead.

```gdscript
card.set_holding()  # Put card into holding state
```

##### get_string() -> String
Returns string representation of the card for debugging.

```gdscript
var card_info = card.get_string()  # Returns card_name
```

#### Static Variables

| Variable | Type | Description |
|----------|------|-------------|
| `hovering_card_count` | `int` | Global count of currently hovering cards |

---

### CardContainer

**Extends:** `Control`

Abstract base class for all card containers. Provides core functionality for holding, managing, and organizing cards with drag-and-drop support.

#### Drop Zone Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_drop_zone` | `bool` | `true` | Enables drop zone functionality |
| `sensor_size` | `Vector2` | `Vector2(0, 0)` | Size of drop sensor (follows card_size if unset) |
| `sensor_position` | `Vector2` | `Vector2(0, 0)` | Position offset for drop sensor |
| `sensor_texture` | `Texture` | - | Visual texture for sensor (debugging) |
| `sensor_visibility` | `bool` | `false` | Whether sensor is visible |

#### Variables

| Variable | Type | Description |
|----------|------|-------------|
| `unique_id` | `int` | Auto-generated unique identifier |
| `cards_node` | `Control` | Node containing all card children |
| `card_manager` | `CardManager` | Reference to parent CardManager |
| `debug_mode` | `bool` | Debug mode state from CardManager |

#### Core Methods

##### add_card(card: Card, index: int = -1) -> void
Adds a card to the container at specified index (-1 for end).

```gdscript
container.add_card(my_card)        # Add to end
container.add_card(my_card, 0)     # Add to beginning
```

##### remove_card(card: Card) -> bool
Removes a card from the container. Returns true if successful.

```gdscript
var success = container.remove_card(my_card)
```

##### has_card(card: Card) -> bool
Checks if container holds the specified card.

```gdscript
if container.has_card(my_card):
    print("Card is in this container")
```

##### get_card_count() -> int
Returns the number of cards currently in the container.

```gdscript
var count = container.get_card_count()
print("Container has %d cards" % count)
```

##### clear_cards() -> void
Removes all cards from the container.

```gdscript
container.clear_cards()
```

##### move_cards(cards: Array, index: int = -1, with_history: bool = true) -> bool
Moves multiple cards to this container with optional history tracking.

```gdscript
var cards_to_move = [card1, card2, card3]
container.move_cards(cards_to_move, 0, true)  # Move to beginning with history
```

##### shuffle() -> void
Randomly shuffles all cards in the container using Fisher-Yates algorithm.

```gdscript
deck_container.shuffle()
```

##### undo(cards: Array, from_indices: Array = []) -> void
Restores cards to their original positions with index precision. Supports both simple restoration and precise index-based positioning for complex undo scenarios.

**Parameters:**
- `cards`: Array of cards to restore to this container
- `from_indices`: Optional array of original indices for precise positioning (since v1.1.4)

**Features:**
- **Adaptive Algorithm**: Automatically detects consecutive vs non-consecutive card groups
- **Order Preservation**: Maintains correct card order for bulk consecutive moves
- **Fallback Safety**: Gracefully handles missing or invalid index data

```gdscript
# Simple undo (backward compatible)
source_container.undo([card1, card2])

# Precise index-based undo (new in v1.1.4)
source_container.undo([card1, card2, card3], [0, 1, 2])

# Handles complex scenarios automatically
hand_container.undo(moved_cards, original_indices)
```

#### Drop Zone Methods

##### check_card_can_be_dropped(cards: Array) -> bool
Determines if the provided cards can be dropped into this container.

```gdscript
if container.check_card_can_be_dropped([my_card]):
    # Cards can be dropped here
```

##### get_partition_index() -> int
Gets the drop partition index based on mouse position. Returns -1 if no partitioning.

```gdscript
var drop_index = container.get_partition_index()
```

#### Event Handlers

##### on_card_move_done(_card: Card) -> void
Called when a card finishes moving. Override in subclasses for custom behavior.

```gdscript
func on_card_move_done(card: Card):
    print("Card movement completed: ", card.card_name)
```

##### on_card_pressed(_card: Card) -> void
Called when a card in this container is pressed. Override for custom behavior.

```gdscript
func on_card_pressed(card: Card):
    print("Card pressed: ", card.card_name)
```

#### Utility Methods

##### hold_card(card: Card) -> void
Puts a card into holding state, preparing it for drag operations.

```gdscript
container.hold_card(my_card)  # Put card into holding state
```

##### get_string() -> String
Returns string representation for debugging.

```gdscript
print(container.get_string())  # "card_container: 1"
```

#### Abstract Methods

These methods should be overridden in subclasses:

##### update_card_ui() -> void
Updates visual positioning and appearance of all cards.

##### _card_can_be_added(_cards: Array) -> bool
Returns true if the specified cards can be added to this container. Base implementation always returns true.

##### _update_target_positions() -> void
Calculates and applies target positions for all cards.

##### _update_target_z_index() -> void
Updates Z-index layering for all cards.

---

### CardFactory

**Extends:** `Node`

Abstract base class for creating cards. Implement this class to define custom card creation logic.

#### Variables

| Variable | Type | Description |
|----------|------|-------------|
| `preloaded_cards` | `Dictionary` | Cache for card data to improve performance |
| `card_size` | `Vector2` | Size to apply to created cards |

#### Abstract Methods

##### create_card(card_name: String, target: CardContainer) -> Card
Creates and returns a new card instance. Must be implemented by subclasses.

```gdscript
# In your custom factory:
func create_card(card_name: String, target: CardContainer) -> Card:
    var new_card = card_scene.instantiate()
    # Configure card...
    return new_card
```

##### preload_card_data() -> void
Preloads card data for improved performance. Called automatically by CardManager.

```gdscript
func preload_card_data() -> void:
    # Load and cache card data
    pass
```

---

### JsonCardFactory

**Extends:** `CardFactory`

Concrete implementation of CardFactory that creates cards from JSON metadata and image assets.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `default_card_scene` | `PackedScene` | Base card scene to instantiate |
| `card_asset_dir` | `String` | Directory containing card image files |
| `card_info_dir` | `String` | Directory containing JSON card definitions |
| `back_image` | `Texture2D` | Common back face texture for all cards |

#### Methods

##### create_card(card_name: String, target: CardContainer) -> Card
Creates a card from JSON data and image assets.

```gdscript
var my_card = factory.create_card("ace_of_spades", target_container)
```

The factory looks for:
- JSON file: `{card_info_dir}/{card_name}.json`
- Image file: `{card_asset_dir}/{front_image}` (from JSON)

#### JSON Card Format

Cards are defined using JSON files with the following structure:

```json
{
    "name": "ace_of_spades",
    "front_image": "cardSpadesA.png",
    "suit": "spades",
    "value": "A",
    "custom_property": "additional_data"
}
```

**Required fields:**
- `front_image`: Filename of the card's front face image

**Optional fields:**
- `name`: Display name for the card
- Any additional properties for game-specific logic

---

## Specialized Containers

### Pile

**Extends:** `CardContainer`

A container that stacks cards in a pile formation with configurable direction and display options.

#### Enums

```gdscript
enum PileDirection {
    UP,     # Cards stack upward
    DOWN,   # Cards stack downward  
    LEFT,   # Cards stack leftward
    RIGHT   # Cards stack rightward
}
```

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `stack_display_gap` | `int` | `8` | Pixel distance between cards in stack |
| `max_stack_display` | `int` | `6` | Maximum cards to show stacked |
| `card_face_up` | `bool` | `true` | Whether cards show front face |
| `layout` | `PileDirection` | `UP` | Direction to stack cards |
| `allow_card_movement` | `bool` | `true` | Whether cards can be moved |
| `restrict_to_top_card` | `bool` | `true` | Only top card is interactive |
| `align_drop_zone_with_top_card` | `bool` | `true` | Drop zone follows top card |

#### Methods

##### get_top_cards(n: int) -> Array
Returns the top N cards from the pile.

```gdscript
var top_three = pile.get_top_cards(3)  # Get top 3 cards
var top_card = pile.get_top_cards(1)[0]  # Get just the top card
```

#### Usage Example

```gdscript
# Create a deck pile
@export var deck_pile: Pile

func _ready():
    deck_pile.layout = Pile.PileDirection.UP
    deck_pile.card_face_up = false  # Cards face down
    deck_pile.restrict_to_top_card = true
    
    # Add cards to deck
    for card_name in card_names:
        var card = card_factory.create_card(card_name, deck_pile)
```

---

### Hand

**Extends:** `CardContainer`

A container that displays cards in a fan-like hand formation with curves and spacing.

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `max_hand_size` | `int` | `10` | Maximum cards that can be held |
| `max_hand_spread` | `int` | `700` | Maximum pixel spread of hand |
| `card_face_up` | `bool` | `true` | Whether cards show front face |
| `card_hover_distance` | `int` | `30` | Distance cards hover when interacted with |

#### Curve Properties

| Property | Type | Description |
|----------|------|-------------|
| `hand_rotation_curve` | `Curve` | Controls rotation of cards across hand |
| `hand_vertical_curve` | `Curve` | Controls vertical positioning of cards |

#### Drop Zone Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `align_drop_zone_size_with_current_hand_size` | `bool` | `true` | Drop zone adapts to hand size |
| `swap_only_on_reorder` | `bool` | `false` | Reordering swaps positions instead of shifting |

#### Methods

##### get_random_cards(n: int) -> Array
Returns N random cards from the hand without removing them.

```gdscript
var random_cards = hand.get_random_cards(3)
```

##### move_cards(cards: Array, index: int = -1, with_history: bool = true) -> bool
Enhanced version of CardContainer.move_cards() with hand-specific optimizations:
- **Single Card Reordering**: Optimized reordering when moving cards within same hand
- **Swap Mode**: Uses swap_card() when `swap_only_on_reorder` is enabled
- **Fallback**: Uses parent implementation for external card moves

```gdscript
# Move card to specific position in hand
hand.move_cards([my_card], 2)  # Move to index 2

# External card move (uses parent implementation)
hand.move_cards([external_card], -1)  # Add external card to end
```

##### swap_card(card: Card, index: int) -> void
Swaps a card with the card at the specified index.

```gdscript
hand.swap_card(my_card, 0)  # Move card to first position
```

#### Usage Example

```gdscript
# Configure hand curves
@export var hand: Hand

func _ready():
    # Create rotation curve: -30° to +30°
    hand.hand_rotation_curve = Curve.new()
    hand.hand_rotation_curve.add_point(0.0, -30.0)
    hand.hand_rotation_curve.add_point(1.0, 30.0)
    
    # Create vertical curve: arc shape
    hand.hand_vertical_curve = Curve.new()
    hand.hand_vertical_curve.add_point(0.0, 0.0)
    hand.hand_vertical_curve.add_point(0.5, 50.0)  # Peak in middle
    hand.hand_vertical_curve.add_point(1.0, 0.0)
```

---

## Supporting Classes

### DraggableObject

**Extends:** `Control`

State machine-based drag-and-drop system with Tween animations. Provides robust interaction handling with safe state transitions and smooth visual feedback.

#### Enums

##### DraggableState
Defines possible interaction states with controlled transitions.

| State | Description |
|-------|-------------|
| `IDLE` | Default state - ready for interaction |
| `HOVERING` | Mouse over with visual feedback |
| `HOLDING` | Active drag state following mouse |
| `MOVING` | Programmatic movement ignoring input |

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `moving_speed` | `int` | `2000` | Speed of programmatic movement (pixels/second) |
| `can_be_interacted_with` | `bool` | `true` | Whether object responds to input |
| `hover_distance` | `int` | `10` | Distance to hover when interacted with |
| `hover_scale` | `float` | `1.1` | Scale multiplier when hovering |
| `hover_rotation` | `float` | `0.0` | Rotation in degrees when hovering |
| `hover_duration` | `float` | `0.10` | Duration for hover animations |

#### State Management

| Variable | Type | Description |
|----------|------|-------------|
| `current_state` | `DraggableState` | Current interaction state |
| `is_pressed` | `bool` | Legacy compatibility - mouse pressed |
| `is_holding` | `bool` | Legacy compatibility - being dragged |
| `stored_z_index` | `int` | Original Z-index before interactions |

#### Methods

##### move(target_destination: Vector2, degree: float) -> void
Moves object to target position with optional rotation using smooth Tween animation. Automatically transitions to MOVING state.

```gdscript
draggable.move(new_position, deg_to_rad(45))  # Move with 45° rotation
draggable.move(Vector2(100, 200), 0)         # Move without rotation
```

##### return_to_original() -> void
Returns the object to its original position with smooth animation. Sets internal tracking flag for proper position management.

```gdscript
draggable.return_to_original()  # Return to original position and rotation
```

##### change_state(new_state: DraggableState) -> bool
Safely transitions between interaction states using predefined rules. Returns true if transition was successful.

```gdscript
# Manual state transitions
if draggable.change_state(DraggableObject.DraggableState.HOVERING):
    print("Now hovering")

# State machine prevents invalid transitions
draggable.change_state(DraggableObject.DraggableState.MOVING)  # Force to MOVING
```

**State Transition Rules:**
- `IDLE` → `HOVERING`, `HOLDING`, `MOVING`
- `HOVERING` → `IDLE`, `HOLDING`, `MOVING`  
- `HOLDING` → `IDLE`, `MOVING`
- `MOVING` → `IDLE`

#### Virtual Methods

##### _on_move_done() -> void
Called when movement animation completes. Override in subclasses for custom behavior.

```gdscript
func _on_move_done():
    print("Movement finished")
    # Custom post-movement logic
```

##### _can_start_hovering() -> bool
Virtual method to determine if hovering animation can start. Override for custom conditions.

```gdscript
func _can_start_hovering() -> bool:
    return not is_card_locked  # Example: prevent hover if locked
```

#### Animation System

The new Tween-based animation system provides:
- **Smooth Transitions**: All state changes use smooth animations
- **Memory Management**: Proper cleanup of animation resources
- **Interrupt Handling**: Safe animation interruption and cleanup
- **Performance**: Optimized for multiple simultaneous animations

---

### DropZone

**Extends:** `Control`

Handles drop detection and partitioning for card containers.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `sensor_size` | `Vector2` | Size of the drop detection area |
| `sensor_position` | `Vector2` | Position offset of the sensor |
| `sensor_texture` | `Texture` | Visual texture for debugging |
| `sensor_visible` | `bool` | Whether sensor is visible |
| `sensor_outline_visible` | `bool` | Whether debug outline is visible |
| `accept_types` | `Array` | Array of acceptable drop types |

#### Variables

| Variable | Type | Description |
|----------|------|-------------|
| `vertical_partition` | `Array` | Global X coordinates for vertical partitions |
| `horizontal_partition` | `Array` | Global Y coordinates for horizontal partitions |

#### Methods

##### init(_parent: Node, accept_types: Array = []) -> void
Initializes the drop zone with parent reference and accepted types.

```gdscript
drop_zone.init(self, ["card"])
```

##### check_mouse_is_in_drop_zone() -> bool
Returns true if mouse cursor is within the drop zone area.

```gdscript
if drop_zone.check_mouse_is_in_drop_zone():
    # Mouse is over drop zone
```

##### set_sensor(_size: Vector2, _position: Vector2, _texture: Texture, _visible: bool) -> void
Configures the drop sensor properties.

```gdscript
drop_zone.set_sensor(Vector2(200, 300), Vector2(10, 10), null, false)
```

##### set_vertical_partitions(positions: Array) -> void
Sets vertical partition lines for precise drop positioning.

```gdscript
drop_zone.set_vertical_partitions([100, 200, 300])  # Three partition lines
```

##### set_horizontal_partitions(positions: Array) -> void
Sets horizontal partition lines for precise drop positioning.

```gdscript
drop_zone.set_horizontal_partitions([50, 150, 250])  # Three partition lines
```

##### get_vertical_layers() -> int
Returns the vertical partition index under the mouse cursor.

```gdscript
var partition = drop_zone.get_vertical_layers()
if partition != -1:
    print("Dropping in partition: ", partition)
```

##### get_horizontal_layers() -> int
Returns the horizontal partition index under the mouse cursor.

---

### HistoryElement

**Extends:** `Object`

Represents a single card movement operation for undo functionality.

#### Variables

| Variable | Type | Description |
|----------|------|-------------|
| `from` | `CardContainer` | Source container |
| `to` | `CardContainer` | Destination container |
| `cards` | `Array` | Array of cards that were moved |

#### Methods

##### get_string() -> String
Returns string representation for debugging.

```gdscript
var history_info = history_element.get_string()
# Returns: "from: [container_1], to: [container_2], cards: [ace_of_spades, king_of_hearts]"
```

---

## Usage Patterns

### Basic Setup

```gdscript
# Scene structure:
# CardManager (CardManager)
# ├── DeckPile (Pile)  
# ├── PlayerHand (Hand)
# └── DiscardPile (Pile)

@onready var card_manager: CardManager = $CardManager
@onready var deck: Pile = $CardManager/DeckPile
@onready var hand: Hand = $CardManager/PlayerHand

func _ready():
    # Cards are automatically managed by CardManager
    deal_initial_cards()

func deal_initial_cards():
    var cards_to_deal = deck.get_top_cards(7)
    hand.move_cards(cards_to_deal)
```

### Custom Container

```gdscript
class_name CustomPile
extends CardContainer

@export var max_cards: int = 5

func _card_can_be_added(cards: Array) -> bool:
    return _held_cards.size() + cards.size() <= max_cards

func _update_target_positions():
    for i in range(_held_cards.size()):
        var card = _held_cards[i]
        var offset = Vector2(i * 20, i * 5)  # Slight offset for each card
        card.move(global_position + offset, 0)
```

### Custom Card Factory

```gdscript
class_name MyCardFactory
extends CardFactory

@export var custom_card_scene: PackedScene

func create_card(card_name: String, target: CardContainer) -> Card:
    var card = custom_card_scene.instantiate()
    card.card_name = card_name
    # Custom card setup logic
    return card

func preload_card_data():
    # Custom preloading logic
    pass
```

This API reference provides complete documentation for all public methods and properties in the Card Framework. For implementation examples, see the included example projects and the FreeCell game demonstration.