# FreeCell - Card Framework Advanced Example

A complete FreeCell Solitaire game demonstrating how to **extend Card Framework** for complex game rules. This example shows practical implementation patterns for creating production-ready card games.

![FreeCell Screenshot](../addons/card-framework/screenshots/freecell.png)

## What This Example Shows

**Card Framework Extension Patterns:**
- Custom `CardContainer` classes with game-specific rules
- Extended `Card` class with suit/rank properties  
- Specialized `CardFactory` for game-specific card creation
- Advanced move validation and multi-card sequences
- Production features (statistics, save/resume, undo system)

## How to Run

1. **Open Scene**: `freecell/scenes/menu/menu.tscn`
2. **Run** with F6 or Play Scene button
3. **Start Game**: Choose seed or play random game
4. **Controls**: Drag cards between containers following FreeCell rules

## Card Framework Extensions

### 1. Custom Card Class - `PlayingCard`

**File**: `scenes/card/playing_card.gd`

```gdscript
class_name PlayingCard extends Card

enum Suit { CLUB, DIAMOND, HEART, SPADE }
enum Number { _A, _2, _3, _4, _5, _6, _7, _8, _9, _10, _J, _Q, _K }

@export var suit: Suit
@export var number: Number
@export var color: Color

# Framework extension - adds game-specific logic
func is_next_number(card: PlayingCard) -> bool:
    return card.number == self.number + 1

func is_different_color(card: PlayingCard) -> bool:
    return self.color != card.color
```

**Key Learning**: How to extend base `Card` class with game-specific properties and methods.

### 2. Custom Containers with Game Rules

#### Foundation (Suit-specific, Ascending)
**File**: `scenes/card_container/foundation.gd`

```gdscript
class_name Foundation extends CardContainer

func check_card_can_be_dropped(cards: Array) -> bool:
    if cards.size() != 1: return false
    var card = cards[0] as PlayingCard
    
    # Empty foundation - must start with Ace
    if _held_cards.is_empty():
        return card.number == PlayingCard.Number._A
    
    # Must match suit and be next number
    var top_card = get_top_cards(1)[0] as PlayingCard
    return top_card.suit == card.suit and top_card.is_next_number(card)
```

#### Tableau (Alternating Colors, Descending)
**File**: `scenes/card_container/tableau.gd`

```gdscript
class_name Tableau extends CardContainer

func check_card_can_be_dropped(cards: Array) -> bool:
    # Empty tableau accepts any card
    if _held_cards.is_empty(): return true
    
    # Must be different color and descending order
    var top_card = get_top_cards(1)[0] as PlayingCard
    var bottom_card = cards[0] as PlayingCard
    return top_card.is_next_number(bottom_card) and top_card.is_different_color(bottom_card)

# Multi-card sequence handling
func get_valid_sequence_from_top(card: Card) -> Array[Card]:
    # Returns valid sequence starting from clicked card
    # Enables multi-card moves in FreeCell
```

#### FreeCell (Single Card Storage)
**File**: `scenes/card_container/freecell.gd`

```gdscript
class_name Freecell extends CardContainer

func check_card_can_be_dropped(cards: Array) -> bool:
    # Only accepts single cards, only when empty
    return cards.size() == 1 and _held_cards.is_empty()
```

**Key Learning**: How to create game-specific validation rules by overriding `check_card_can_be_dropped()`.

### 3. Custom Card Factory

**File**: `scenes/card_factory/freecell_card_factory.gd`

```gdscript
class_name FreecellCardFactory extends JsonCardFactory

func create_card(card_name: String, target: CardContainer) -> Card:
    var playing_card = super.create_card(card_name, target) as PlayingCard
    
    # Add FreeCell-specific properties from JSON
    var card_data = get_card_info(card_name)
    playing_card.suit = _string_to_suit(card_data.suit)
    playing_card.number = _string_to_number(card_data.value)
    playing_card.color = _get_color_from_suit(playing_card.suit)
    
    return playing_card
```

**Key Learning**: How to extend `JsonCardFactory` to create specialized card objects.

## Advanced Game Features

### Multi-Card Movement ("Super Move")

```gdscript
# Calculate maximum moveable sequence based on empty spaces
func maximum_number_of_super_move(tableau: Tableau) -> int:
    var empty_freecells = _count_remaining_freecell()
    var empty_tableaus = _count_remaining_tableaus()
    return pow(2, empty_tableaus) * (empty_freecells + 1)

# Enable multi-card drag when sequence is valid
func hold_multiple_cards(card: Card, tableau: Tableau) -> void:
    var valid_sequence = tableau.get_valid_sequence_from_top(card)
    var max_moveable = maximum_number_of_super_move(tableau)
    
    if valid_sequence.size() <= max_moveable:
        for sequence_card in valid_sequence:
            sequence_card.set_holding()
```

### Auto-Move System

```gdscript
# Automatically move cards to foundations when safe
func _check_auto_move() -> void:
    for tableau in _tableaus:
        if tableau.get_card_count() == 0: continue
        
        var top_card = tableau.get_top_cards(1)[0] as PlayingCard
        var foundation = _get_foundation_for_suit(top_card.suit)
        
        if _is_safe_to_auto_move(top_card):
            foundation.move_cards([top_card])
```

### Game State Management

```gdscript
# Central game coordinator
func _ready() -> void:
    _set_record_manager()    # Statistics database
    _set_containers()        # Link container references  
    _set_auto_mover()        # Auto-move system
    _set_game_timer()        # Time tracking
    _deal_new_game()         # Initial card distribution

func _check_game_state() -> void:
    if _all_foundations_complete():
        game_state = GameState.WIN
        _show_result_popup(true)
```

## Learning Architecture Patterns

### 1. **Container Specialization Pattern**
- Base: `CardContainer` provides drag-and-drop
- Extend: Override `check_card_can_be_dropped()` for game rules
- Result: Type-safe, rule-enforced card placement

### 2. **Card Extension Pattern**  
- Base: `Card` provides visuals and movement
- Extend: Add game-specific properties (suit, rank, color)
- Result: Rich card objects for complex game logic

### 3. **Factory Customization Pattern**
- Base: `JsonCardFactory` provides JSON loading
- Extend: Parse additional data into custom card properties
- Result: Seamless integration of game data with Card Framework

### 4. **Event-Driven Updates Pattern**
```gdscript
# Game updates triggered by card movements, not polling
func _on_card_moved():
    _check_auto_move()
    _update_interaction_states() 
    _check_game_state()
```

## Project Structure

```
freecell/
├── scenes/
│   ├── card/
│   │   └── playing_card.gd          # Extended Card class
│   ├── card_container/  
│   │   ├── foundation.gd            # Suit-specific ascending
│   │   ├── tableau.gd               # Alternating descending
│   │   └── freecell.gd             # Single card storage
│   ├── card_factory/
│   │   └── freecell_card_factory.gd # PlayingCard creation
│   ├── main_game/
│   │   ├── freecell_game.gd        # Game coordinator
│   │   └── game_generator.gd       # Seed-based dealing
│   └── menu/
│       └── menu.gd                 # Menu system
├── assets/images/
│   ├── cards/                      # Standard 52-card deck
│   └── spots/                      # Empty container indicators
└── card_info/                     # JSON card definitions
```

## Key Takeaways for Your Games

1. **Rule Implementation**: Override `check_card_can_be_dropped()` for custom placement rules
2. **Card Extensions**: Add properties via inheritance, not base class modification
3. **Factory Patterns**: Customize card creation without changing core framework
4. **Multi-Container Logic**: Coordinate between containers for complex interactions
5. **Performance**: Update game state on events, not every frame

## Adapting for Other Games

**For Klondike Solitaire**:
- Modify `Tableau` to support face-down cards
- Adjust `Foundation` for any-suit-to-empty rule
- Add `Stock` container for draw pile

**For Spider Solitaire**:
- Create `SpiderTableau` for suit-sequence building
- Modify `Foundation` to accept complete King-to-Ace sequences
- Remove FreeCell containers entirely

**Next Steps**: Study the implementation files to see these patterns in action, then adapt them for your own card game ideas!