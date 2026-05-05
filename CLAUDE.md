# Card Framework - Claude Code Project Guide

## Project Overview

**Card Framework** is a Godot 4.x addon for building 2D card games (Solitaire, TCGs, deck-builders, etc.). Lightweight, extensible, with drag-and-drop, JSON-driven card data, and editor previews.

- **Engine**: Godot 4.6+
- **License**: MIT
- **Status**: Production-ready, current version tracked in `README.md`

For user-facing setup, install steps, and feature highlights, see `README.md`. This file is the contributor/Claude context guide.

## Architecture

### Core Components
```
CardManager (root orchestrator, move history)
├── CardFactory (abstract) → JsonCardFactory (concrete)
├── CardContainer (abstract) → Pile | Hand
├── Card (extends DraggableObject)
└── DropZone (interaction sensor)
```

### Design Patterns
- **Factory** — `CardFactory` / `JsonCardFactory` for card creation
- **Template Method** — `CardContainer` exposes virtual hooks (`check_card_can_be_dropped`, etc.)
- **Observer** — signal-driven movement and interaction callbacks
- **Strategy** — drag-and-drop pluggability via `DraggableObject`

### Repo Layout
- `addons/card-framework/` — framework source (the addon itself)
- `example1/` — minimal demo
- `freecell/` — full FreeCell implementation
- `docs/` — `GETTING_STARTED.md`, `API.md`, `CHANGELOG.md`, `index.md`
- `scripts/` — release automation (`create-release.ps1` / `.sh`)

## Code Standards

### GDScript
- Strong typing on signatures: `func create_card(name: String) -> Card`
- `snake_case` for vars/funcs, `PascalCase` for classes
- `##` doc comments on public APIs
- `@export` for designer-tunable properties
- `@tool` blocks must guard editor-only logic (the framework supports in-editor preview)

### Godot 4.x
- `class_name` for reusable types
- `@onready` for node references
- Signals over direct coupling
- `Curve` / `Resource` types for tunable configuration

### Framework Rules
- Extend, don't modify: subclass `CardContainer`, `Card`, or `CardFactory` rather than editing core
- Maintain JSON schema compatibility when extending card data
- `CardManager` stays the central orchestrator — containers and factories register through it

## Extension Patterns

### Custom Container
```gdscript
class_name MyContainer
extends CardContainer

func check_card_can_be_dropped(cards: Array) -> bool:
    return true  # game-specific rules

func on_card_move_done(card: Card) -> void:
    # post-movement hook (scoring, win check, etc.)
    pass
```

### Custom Card
```gdscript
class_name GameCard
extends Card

@export var power: int
@export var cost: int

func _ready():
    super._ready()
    # initialize from card_info
```

## Key Configuration

### CardManager
- `card_size` — default card dimensions
- `card_factory_scene` — assigned factory
- `debug_mode` — visualizes drop-zone sensors

### JsonCardFactory
- `card_asset_dir` — card image directory
- `card_info_dir` — JSON card definitions
- `back_image` — default card back

### Hand
- `hand_anchor` — `HandAnchor` enum controls fan alignment

### JSON Card Schema
```json
{
    "name": "club_2",
    "front_image": "cardClubs2.png",
    "suit": "club",
    "value": "2"
}
```

## Common Patterns

- **Movement**: `card.move(target_position, rotation_degrees)`; `moving_speed` controls animation; completion via `on_card_move_done()`
- **Undo/redo**: `move_cards()` records to `CardManager` history
- **Performance**: `factory.preload_card_data()`, `Pile.max_stack_display` for large stacks
- **Editor preview**: framework uses `@tool` across containers and factories — layout/preview updates live from the Inspector
- **Container parents**: `Pile`/`Hand` work as children of Godot `Container` nodes (use `global_position` for sensor math)

## Troubleshooting

- **Cards not appearing** — check `card_asset_dir` and image filenames match JSON `front_image`
- **JSON errors** — validate syntax and required fields (`name`, `front_image`)
- **Drag-and-drop dead** — confirm `enable_drop_zone = true` on the container
- **Sensor misalignment** — likely a `position` vs `global_position` issue when nested in a `Container`
- **Slow with large decks** — toggle `debug_mode`, then preload data and cap `max_stack_display`

## Validation Before Marking Work Done

- Run both `example1/example1.tscn` and `freecell/scenes/menu/menu.tscn`
- Check the Godot editor for `@tool` errors (preview must not crash the editor)
- Confirm JSON-driven cards still load from `card_info_dir`

## Release Process

Full procedure in `scripts/README.md`. Quick reference:

1. Bump version in `README.md`, `addons/card-framework/README.md`, and add a `docs/CHANGELOG.md` entry
2. Build archive: `./scripts/create-release.sh X.Y.Z` (or `.\scripts\create-release.ps1 X.Y.Z`) → outputs `releases/card-framework-vX.Y.Z-full.zip`
3. Smoke test the archive in Godot (both example scenes)
4. Tag and push: `git tag -a vX.Y.Z -m "Release vX.Y.Z" && git push origin vX.Y.Z`
5. Create GitHub Release, upload the `-full.zip`
6. Update the Asset Library entry if it's a new major/minor
