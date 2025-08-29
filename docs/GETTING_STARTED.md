# Getting Started with Card Framework

Complete step-by-step guide to set up and use the Card Framework in your Godot 4.x projects.

## Prerequisites

- **Godot Engine 4.4+** installed
- Basic knowledge of Godot scenes and nodes
- Understanding of GDScript fundamentals

## Installation Methods

### Method 1: AssetLib Installation (Recommended)

1. **Open Godot Editor** and create or open your project
2. **Navigate to AssetLib** tab in the main editor
3. **Search** for "Card Framework"
4. **Download** and import the latest version
5. **Verify Installation** - Check `res://addons/card-framework/` exists

### Method 2: Manual Installation

1. **Download** Card Framework from the repository
2. **Extract** the contents to your project
3. **Copy** the `addons/card-framework/` folder to `res://addons/`
4. **Refresh** the FileSystem dock in Godot

## Project Setup

### Step 1: Scene Structure

Create your main game scene with this hierarchy:
```
Main (Node2D)
└── CardManager (CardManager)
    ├── Deck (Pile)
    ├── PlayerHand (Hand) 
    └── DiscardPile (Pile)
```

### Step 2: CardManager Configuration

1. **Add CardManager Scene**
   - In your main scene, **Add Child Node**
   - **Instance** `res://addons/card-framework/card_manager.tscn`

2. **Configure Basic Properties**
   ```
   Card Size: (150, 210)          # Standard playing card dimensions
   Debug Mode: false              # Enable for development
   ```

3. **Create Your Card Factory**
   Instead of using the card factory directly, create your own:
   
   **Option A: Inherit from JsonCardFactory (Recommended)**
   - **Create New Scene** → **Add Node** → **JsonCardFactory**
   - **Save** as `res://scenes/my_card_factory.tscn`
   - **Set** `card_factory_scene` to `res://scenes/my_card_factory.tscn`
   
   **Option B: Create Custom Factory**
   - **Create New Scene** → **Add Node** → **CardFactory**
   - **Attach Script** and implement `create_card()` method
   - **Save** as `res://scenes/my_card_factory.tscn`

### Step 3: Directory Structure Setup

Create this folder structure in your project:
```
res://
├── cards/
│   ├── images/          # Card artwork
│   └── data/           # JSON card definitions
└── scenes/
    └── main.tscn       # Your main scene
```

### Step 4: Card Assets Preparation

#### 4.1 Card Images
- **Format**: PNG recommended (supports transparency)
- **Size**: 150x210 pixels for standard cards
- **Naming**: Use descriptive names (e.g., `cardClubs2.png`, `cardHeartsK.png`)
- **Location**: Store in `res://cards/images/`

#### 4.2 Card Data Files
Create JSON files in `res://cards/data/` for each card:

**Example: `club_2.json`**
```json
{
    "name": "club_2",
    "front_image": "cardClubs2.png",
    "suit": "club",
    "value": "2",
    "color": "black"
}
```

**Required Fields**:
- `name` - Unique identifier for the card
- `front_image` - Filename of the card's front texture

**Optional Fields**:
- Add any custom properties needed for your game logic

### Step 5: Card Factory Configuration

**If using JsonCardFactory (Option A from Step 2):**

Open your `my_card_factory.tscn` scene and configure the JsonCardFactory node:

```
Card Asset Dir: "res://cards/images/"
Card Info Dir: "res://cards/data/"
Back Image: [Assign a card back texture]
Default Card Scene: [Assign custom card scene - required field]
```

**If using Custom Factory (Option B):**
- Implement your own card creation logic in the attached script
- No additional configuration needed here

### Step 6: Container Setup

#### 6.1 Adding Containers

Add container nodes as children of CardManager:

1. **Right-click** CardManager in Scene dock
2. **Add Child** → Choose container type:
   - `Pile` for stacked cards (decks, discard piles)
   - `Hand` for fanned card layouts (player hands)
3. **Position Containers**
   - Select each container in the Scene dock
   - In **Inspector** → **Transform** → **Position**, set appropriate coordinates:
     - Example: Deck at (100, 300), PlayerHand at (400, 500), DiscardPile at (700, 300)
   - Adjust positions based on your game screen size and layout needs

#### 6.2 Pile Configuration

**Basic Properties**:
```
Enable Drop Zone: true
Card Face Up: false             # For deck, true for discard
Layout: UP                      # Stack direction
Allow Card Movement: true
Restrict To Top Card: true      # Only top card moveable
```

**Visual Properties**:
```
Stack Display Gap: 8            # Pixel spacing between cards
Max Stack Display: 6           # Maximum visible cards
```

#### 6.3 Hand Configuration

**Layout Properties**:
```
Max Hand Size: 10
Max Hand Spread: 700           # Pixel width of fanned cards
Card Face Up: true
Card Hover Distance: 30        # Hover effect height
```

**Required Curves** (Create in Inspector):
- `Hand Rotation Curve`: 2-point linear curve for card rotation
- `Hand Vertical Curve`: 3-point curve for arc shape (0→1→0)

### Step 7: Basic Scripting

Add this script to your main scene to start using cards:

```gdscript
extends Node2D

@onready var card_manager = $CardManager
@onready var deck = $CardManager/Deck
@onready var player_hand = $CardManager/PlayerHand

func _ready():
    setup_game()

func setup_game():
    # Create a deck of cards
    create_standard_deck()
    
    # Deal initial hand
    deal_cards_to_hand(5)

func create_standard_deck():
    var suits = ["club", "diamond", "heart", "spade"]
    var values = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
    
    for suit in suits:
        for value in values:
            var card_name = "%s_%s" % [suit, value]
            var card = card_manager.card_factory.create_card(card_name, deck)
            deck.add_card(card)

func deal_cards_to_hand(count: int):
    for i in count:
        if deck.get_card_count() > 0:
            var card = deck.get_top_cards(1).front()
            player_hand.move_cards([card])
```

## Testing Your Setup

### Quick Test Checklist

1. **Run Your Scene** - Press F6 and select your main scene
2. **Verify Cards Appear** - You should see cards in your containers
3. **Test Interactions** - Try dragging cards between containers
4. **Check Debug Mode** - Enable in CardManager to see drop zones
5. **Console Errors** - Ensure no error messages appear

### Common Issues

**Cards Not Appearing**:
- Verify JSON files exist and match card names
- Check `card_asset_dir` and `card_info_dir` paths
- Ensure image files exist in the asset directory

**Drag and Drop Issues**:
- Confirm `enable_drop_zone` is true on containers
- Check that `can_be_interacted_with` is true on cards
- Verify container positions don't overlap incorrectly

**JSON Loading Errors**:
- Validate JSON syntax using online validator
- Ensure required `name` and `front_image` fields exist
- Check for typos in field names

## Next Steps

### Explore Sample Projects
- **`example1/`** - Basic demonstration of all container types
- **`freecell/`** - Complete game implementation with custom rules

### Advanced Customization
- [API Reference](API.md) - Complete class documentation
- [Creating Custom Containers](API.md#extending-cardcontainer)
- [Custom Card Properties](API.md#extending-card)

### Performance Optimization
- Use `preload_card_data()` for better loading performance
- Implement object pooling for frequently created/destroyed cards
- Consider `max_stack_display` for large piles

---

**Need Help?** Check the [API Documentation](API.md) or examine the sample projects for working examples.