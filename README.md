# Card Framework

[![Version](https://img.shields.io/badge/version-1.2.3-blue.svg)](https://github.com/hyunjoon/card-framework)
[![Godot](https://img.shields.io/badge/Godot-4.4+-green.svg)](https://godotengine.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
[![Platform](https://img.shields.io/badge/platform-cross--platform-lightgrey.svg)]()

**Professional-grade Godot 4.x addon** for building 2D card games. Create **Solitaire**, **TCG**, or **deck-building roguelikes** with flexible card handling and drag-and-drop interactions.

![Example1 Screenshot](addons/card-framework/screenshots/example1.png) ![Freecell Screenshot](addons/card-framework/screenshots/freecell.png)

## Key Features

• **Drag & Drop System** - Intuitive card interactions with built-in validation  
• **Flexible Containers** - `Pile` (stacks), `Hand` (fanned layouts), custom containers  
• **JSON Card Data** - Define cards with metadata, images, and custom properties  
• **Production Ready** - Complete FreeCell implementation included  
• **Extensible Architecture** - Factory patterns, inheritance hierarchy, event system

## Installation

**From AssetLib:** Search "Card Framework" in Godot's AssetLib tab  
**Manual:** Copy contents to `res://addons/card-framework`

## Quick Start

1. **Add CardManager** - Instance `card-framework/card_manager.tscn` in your scene
2. **Configure Factory** - Assign `JsonCardFactory` to `card_factory_scene`  
3. **Set Directories** - Point `card_asset_dir` to images, `card_info_dir` to JSON files
4. **Add Containers** - Create `Pile` or `Hand` nodes as children of CardManager

### Basic Card JSON
```json
{
    "name": "club_2",
    "front_image": "cardClubs2.png",
    "suit": "club",
    "value": "2"
}
```

## Core Architecture

**CardManager** - Root orchestrator managing factories, containers, and move history  
**Card** - Individual card nodes with animations, face states, interaction properties  
**CardContainer** - Base class for `Pile` (stacks) and `Hand` (fanned layouts)  
**CardFactory** - Creates cards from JSON data, supports custom implementations

## Sample Projects

**`example1/`** - Basic demonstration with different container types  
**`freecell/`** - Complete game with custom rules, statistics, seed generation

Run: `res://example1/example1.tscn` or `res://freecell/scenes/menu/menu.tscn`

## Customization

**Custom Containers** - Extend `CardContainer`, override `check_card_can_be_dropped()`  
**Custom Cards** - Extend `Card` class for game-specific properties  
**Custom Factories** - Extend `CardFactory` for database/procedural card creation

## Documentation

• **[Getting Started Guide](docs/GETTING_STARTED.md)** - Complete setup and configuration  
• **[API Reference](docs/API.md)** - Full class documentation and method reference  
• **[Changelog](docs/CHANGELOG.md)** - Version history and upgrade guide  
• **[Documentation Index](docs/index.md)** - Complete documentation overview

## Contributing

1. Fork repository
2. Create feature branch  
3. Commit with clear messages
4. Open pull request with problem description

## License & Credits

**Framework**: Open source  
**Card Assets**: [Kenney.nl](https://kenney.nl/assets/boardgame-pack) (CC0 License)  
**Version**: 1.2.3 (Godot 4.4+ compatible)

**Thanks to:** [Kenney.nl](https://kenney.nl/assets/boardgame-pack), [InsideOut-Andrew](https://github.com/insideout-andrew/simple-card-pile-ui), [Rosetta Code FreeCell](https://rosettacode.org/wiki/Deal_cards_for_FreeCell)