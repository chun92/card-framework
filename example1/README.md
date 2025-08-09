# Card Framework - Basic Example

## Welcome to Card Game Development!

This beginner-friendly example demonstrates the core concepts of the Card Framework addon. Perfect for newcomers to both Godot and card game development, this interactive demo shows you how to create, move, and manage cards in a 2D environment.

## What You'll Learn

- **Card Creation**: How cards are generated from JSON data and images
- **Container System**: Understanding Hands, Piles, and card organization
- **Drag & Drop**: Interactive card movement between containers
- **Game Logic**: Basic card manipulation and state management
- **Framework Structure**: Core components and their relationships

## Quick Start (5 Minutes)

1. **Open the Project**: Launch Godot 4.4+ and open this card-framework project
2. **Navigate to Example**: Go to `example1/example1.tscn` in the FileSystem dock
3. **Run the Scene**: Press F6 or click "Play Scene" in the toolbar
4. **Start Experimenting**: Click buttons and drag cards to explore!

## Interactive Features

The example provides several buttons to help you understand card operations:

### Card Drawing
- **Draw 1**: Moves one card from deck to hand
- **Draw 3**: Attempts to draw 3 cards (handles empty deck gracefully)  
- **Draw 3 at Front**: Places drawn cards at the beginning of hand

### Card Organization  
- **Shuffle Hand**: Randomizes card order in hand
- **Move to Pile 1-4**: Sends random hand cards to different piles
- **Discard 1/3**: Moves cards from hand to discard pile

### Game Management
- **Reset Deck**: Regenerates full shuffled deck of 52 cards
- **Undo**: Reverses the last card movement operation
- **Clear All**: Resets entire game state
- **Toggle Discard**: Enables/disables drag-and-drop for discard pile

## Understanding the Code

### Core Components

```gdscript
# Key references in example1.gd
@onready var card_manager = $CardManager      # Central orchestrator
@onready var card_factory = $CardManager/MyCardFactory  # Card creator
@onready var hand = $CardManager/Hand         # Player's hand container
@onready var deck = $CardManager/Deck         # Draw pile
```

### Card Creation Process

The framework uses a factory pattern to create cards:

```gdscript
# Cards are created from JSON definitions
func _get_randomized_card_list() -> Array:
    var suits = ["club", "spade", "diamond", "heart"] 
    var values = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
    
    # Generates names like "club_A", "spade_K" 
    # These match JSON files in card_info/ directory
```

### Movement System

Cards move between containers using a simple API:

```gdscript
# Draw cards from deck to hand
hand.move_cards(deck.get_top_cards(1))

# Move random cards between containers
var cards = hand.get_random_cards(3)
discard.move_cards(cards)
```

## File Structure Overview

```
example1/
├── example1.tscn          # Main scene file
├── example1.gd           # Game logic and button handlers  
├── my_card_factory.tscn  # Card creation configuration
├── assets/images/cards/  # Card artwork (Kenney.nl assets)
└── card_info/            # JSON card definitions
    ├── club_A.json       # Sample: {"name": "club_A", "front_image": "cardClubsA.png", ...}
    └── ...               # One JSON file per card
```

## Customization Guide

### Adding New Cards

1. **Add Image**: Place PNG file in `assets/images/cards/`
2. **Create JSON**: Add matching file in `card_info/` directory
3. **Update Logic**: Modify `_get_randomized_card_list()` to include new cards

### Modifying Containers

Try these safe experiments:

```gdscript
# Change hand layout (in scene editor)
hand.max_cards_per_row = 7  # Cards per row in hand display

# Modify pile behavior  
pile1.enable_drop_zone = false  # Disable drag-and-drop
pile1.max_stack_display = 3     # Show only top 3 cards
```

### Visual Customization

- **Card Back**: Change `back_image` property in CardFactory scene
- **Card Size**: Adjust `card_size` in CardManager node  
- **Animation Speed**: Modify `moving_speed` on individual cards

## Safe Experimentation Tips

- **Always Save First**: Create backup before major changes
- **Use Debug Mode**: Enable `debug_mode` in CardManager to visualize drop zones
- **Start Small**: Modify existing button functions rather than creating new systems
- **Test Frequently**: Run the scene after each change to catch issues early

## Common Beginner Questions

**Q: Why aren't my cards appearing?**  
A: Check that image filenames in `card_info/*.json` match actual files in `assets/images/cards/`

**Q: Can I add custom card properties?**  
A: Yes! Add new fields to JSON files, then extend Card class to use them

**Q: How do I create new container types?**  
A: Extend the CardContainer class and override methods like `check_card_can_be_dropped()`

## Next Steps: Level Up Your Skills

Ready for more advanced concepts? Check out the **FreeCell Example** (`/freecell/`) which demonstrates:

- Complete game implementation with win/lose conditions
- Custom card containers with game-specific rules
- Advanced features like auto-move, statistics tracking
- Production-ready architecture patterns
- Database integration and persistence

The FreeCell example shows how this simple framework scales to create full-featured card games!

## Getting Help

- **Framework Documentation**: See main project README.md
- **Godot Resources**: [Godot 4.x Documentation](https://docs.godotengine.org/)
- **Card Assets**: Uses [Kenney.nl Card Pack](https://www.kenney.nl/assets/boardgame-pack) (CC0 License)

Happy card game developing! 🎴