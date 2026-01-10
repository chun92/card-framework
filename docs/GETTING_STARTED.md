# Getting Started with Card Framework

Complete step-by-step guide to set up and use the Card Framework in your Godot 4.x projects.

## Prerequisites

- **Godot Engine 4.5+** installed
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

The Card Framework supports flexible scene layouts. CardManager must be positioned **above** CardContainers in the scene tree, but doesn't require direct parent-child relationships.

**Option A: Traditional Layout (Direct Children)**
```
Main (Node2D)
└── CardManager (CardManager)
    ├── Deck (Pile)
    ├── PlayerHand (Hand)
    └── DiscardPile (Pile)
```

**Option B: Flexible Layout (Modern UI Structure)**
```
Main (Node2D)
├── CardManager (CardManager)
├── GameUI (Control)
│   ├── TopPanel (HBoxContainer)
│   │   └── Deck (Pile)
│   └── BottomPanel (VBoxContainer)
│       ├── PlayerHand (Hand)
│       └── ActionButtons (HBoxContainer)
└── PlayArea (Control)
    └── DiscardPile (Pile)
```

> **Key Rule**: CardManager must be positioned higher in the scene tree than any CardContainer nodes. The framework automatically discovers all CardContainers regardless of their position in complex UI hierarchies.

### Step 2: CardManager Configuration

After adding CardManager to your scene (as shown in Step 1), configure its properties:

1. **Configure Basic Properties**
   ```
   Card Size: (150, 210)          # Standard playing card dimensions
   Debug Mode: false              # Enable for development
   ```

2. **Create Your Card Factory**
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
Default Card Scene: [Assign custom card scene or leave empty for framework default]
```

**If using Custom Factory (Option B):**
- Implement your own card creation logic in the attached script
- No additional configuration needed here

### Step 6: Custom Card Scene (Optional)

The Card Framework uses a flexible TextureRect assignment system that supports both default and custom card scene structures. This step is optional for basic usage but provides powerful customization options.

#### 6.1 Understanding Card Scene Structure

**Default Card Scene Structure:**
```
Card (Card)
├── FrontFace (Control)
│   └── TextureRect
└── BackFace (Control)
    └── TextureRect
```

The framework automatically finds these nodes using the fallback pattern:
- `front_face_texture` → `$FrontFace/TextureRect`
- `back_face_texture` → `$BackFace/TextureRect`

#### 6.2 Using Default Structure (Recommended for Beginners)

**No action needed!** The framework handles everything automatically:

1. JsonCardFactory creates cards using the default scene structure
2. TextureRect nodes are found automatically via fallback paths
3. Cards work immediately without any additional setup

#### 6.3 Creating Custom Card Scenes

For advanced customization, create your own card scene structure:

**Step 1: Create Custom Card Scene**
1. **Scene** → **New Scene** → **Create Card Node**
2. **Add your custom structure:**
   ```
   MyCustomCard (Card)
   ├── UI (Control)
   │   ├── FrontDisplay (TextureRect)  # Custom front node
   │   └── BackDisplay (TextureRect)   # Custom back node
   └── Effects (Node2D)  # Additional custom nodes
   ```
3. **Save** as `res://scenes/custom_card.tscn`

**Step 2: Configure JsonCardFactory**
1. Open your `my_card_factory.tscn` scene
2. Set **Default Card Scene** to `res://scenes/custom_card.tscn`

**Step 3: Assign Custom TextureRect Nodes**

**Option A: In Scene (Inspector)**
1. Open your custom card scene
2. Select the Card node
3. In **Inspector**, assign:
   - **Front Face Texture** → `FrontDisplay` node
   - **Back Face Texture** → `BackDisplay` node

**Option B: In Script (Programmatic)**
```gdscript
# In your card factory or setup code
func setup_custom_card(card: Card):
    card.front_face_texture = card.get_node("UI/FrontDisplay")
    card.back_face_texture = card.get_node("UI/BackDisplay")
```

#### 6.4 Advanced Customization Examples

**Example 1: Animated Card**
```
AnimatedCard (Card)
├── AnimationPlayer
├── FrontSide (Control)
│   ├── TextureRect        # Still uses fallback!
│   └── ParticleSystem2D
└── BackSide (Control)
    ├── TextureRect        # Still uses fallback!
    └── GlowEffect
```

**Example 2: 3D-Style Card**
```
Card3D (Card)
├── FrontFace (Control)
│   ├── TextureRect
│   └── ShadowEffect
├── BackFace (Control)
│   ├── TextureRect
│   └── ReflectionEffect
└── Transform3D (Node2D)
```


### Step 7: Container Setup

#### 7.1 Adding Containers

Add container nodes to your scene. They can be direct children of CardManager or placed anywhere in your UI hierarchy (as shown in Step 1):

**For Traditional Layout (Option A):**
1. **Right-click** CardManager in Scene dock
2. **Add Child** → Choose container type

**For Flexible Layout (Option B):**
1. **Right-click** the appropriate UI node (e.g., TopPanel, BottomPanel, PlayArea)
2. **Add Child** → Choose container type

**Container Types:**
- `Pile` for stacked cards (decks, discard piles)
- `Hand` for fanned card layouts (player hands)

3. **Position Containers**
   - Select each container in the Scene dock
   - In **Inspector** → **Transform** → **Position**, set appropriate coordinates:
     - Example: Deck at (100, 300), PlayerHand at (400, 500), DiscardPile at (700, 300)
   - Adjust positions based on your game screen size and layout needs

#### 7.2 Pile Configuration

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

#### 7.3 Hand Configuration

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

### Step 8: Basic Scripting

Add this script to your main scene to start using cards:

```gdscript
extends Node2D

@onready var card_manager = $CardManager

# For Traditional Layout (Option A):
@onready var deck = $CardManager/Deck
@onready var player_hand = $CardManager/PlayerHand

# For Flexible Layout (Option B) - adjust paths as needed:
# @onready var deck = $GameUI/TopPanel/Deck
# @onready var player_hand = $GameUI/BottomPanel/PlayerHand

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

**CardContainer Discovery Issues**:
- Ensure CardManager is positioned higher in scene tree than CardContainers
- Check console for helpful error messages about CardManager positioning
- Verify CardContainers are properly instantiated in the scene

**Custom Card Scene Issues**:
- **Cards not displaying textures**: Verify TextureRect nodes are assigned in Inspector, check fallback paths `$FrontFace/TextureRect` and `$BackFace/TextureRect`, ensure custom nodes are properly structured
- **Console Error "Card requires front_face_texture and back_face_texture"**: The framework couldn't find TextureRect nodes - either assign them manually in Inspector or use standard fallback structure, check node names and paths are correct

## Next Steps

### Explore Sample Projects
- **`example1/`** - Basic demonstration of all container types
- **`freecell/`** - Complete game implementation with custom rules

### Advanced Customization
- [API Reference](API.md) - Complete class documentation
- [Creating Custom Containers](API.md#cardcontainer)
- [Custom Card Properties](API.md#card)

### Performance Optimization
- Use `preload_card_data()` for better loading performance
- Implement object pooling for frequently created/destroyed cards
- Consider `max_stack_display` for large piles

---

**Need Help?** Check the [API Documentation](API.md) or examine the sample projects for working examples.