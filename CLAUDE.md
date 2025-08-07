# Card Framework - Claude Code Project Guide

## Project Overview

**Card Framework** is a professional-grade Godot 4.x addon for creating 2D card games. This lightweight, extensible toolkit supports various card game genres from classic Solitaire to complex TCGs and deck-building roguelikes.

### Key Characteristics
- **Target Engine**: Godot 4.4.1
- **Architecture**: Modular addon with factory patterns and inheritance hierarchy
- **License**: Open source with CC0 assets
- **Status**: Production-ready (v1.1.3) with comprehensive examples

## Architecture Overview

### Core Components
```
CardManager (Root orchestrator)
├── CardFactory (Abstract) → JsonCardFactory (Concrete)
├── CardContainer (Abstract) → Pile/Hand (Specialized containers)
├── Card (extends DraggableObject)
└── DropZone (Interaction handling)
```

### Design Patterns in Use
- **Factory Pattern**: Flexible card creation via CardFactory/JsonCardFactory
- **Template Method**: CardContainer with overridable methods for game-specific logic
- **Observer Pattern**: Event-driven card movement and interaction callbacks
- **Strategy Pattern**: Pluggable drag-and-drop via DraggableObject inheritance

### File Structure
- `addons/card-framework/` - Core framework code
- `example1/` - Basic demonstration project
- `freecell/` - Complete FreeCell game implementation
- `project.godot` - Godot 4.4+ project configuration

## Development Guidelines

### Code Standards
1. **GDScript Best Practices**
   - Use strong typing: `func create_card(name: String) -> Card`
   - Follow naming conventions: `card_container`, `front_face_texture`
   - Document public APIs with `##` comments
   - Use `@export` for designer-configurable properties

2. **Godot 4.x Compliance**
   - Use `class_name` declarations for reusable classes
   - Prefer `@onready` for node references
   - Use signals for decoupled communication
   - Leverage Resource system for configuration (Curve resources)

3. **Framework Architecture Rules**
   - Inherit from CardContainer for new container types
   - Extend CardFactory for custom card creation logic
   - Use CardManager as the central orchestrator
   - Maintain JSON compatibility for card data when using JsonCardFactory

### Extension Patterns

#### Creating Custom Card Containers
```gdscript
class_name MyCustomContainer
extends CardContainer

func check_card_can_be_dropped(cards: Array) -> bool:
    # Implement game-specific rules
    return true

func add_card(card: Card, index: int = -1) -> void:
    # Custom card placement logic
    super.add_card(card, index)
```

#### Extending Card Properties
```gdscript
class_name GameCard
extends Card

@export var power: int
@export var cost: int
@export var effect: String

func _ready():
    super._ready()
    # Initialize custom properties from card_info
```

## Claude Code Usage Patterns

### Quick Commands for Development

#### Analysis and Exploration
```bash
# Analyze specific components
/godot-analyze Card
/godot-analyze CardContainer
/godot-analyze "drag and drop system"

# Review architecture
/analyze addons/card-framework/ --focus architecture
```

#### Implementation Tasks
```bash
# Add new features
/godot-implement "deck shuffling animation"
/godot-implement "card effect system" 

# Create custom containers
/godot-implement "discard pile with auto-organize"
```

#### Testing and Validation
```bash
# Create tests
/godot-test unit Card
/godot-test integration "hand reordering"
/godot-test performance "large deck handling"
```

### Development Workflow

#### 1. Understanding Existing Code
- Start with `/godot-analyze [component]` to understand structure
- Use `/analyze` for deeper architectural investigation
- Read example implementations in `freecell/` for complex patterns

#### 2. Planning New Features
- Create task breakdown using TodoWrite
- Consider compatibility with existing CardContainer interface
- Plan JSON schema changes if extending card properties

#### 3. Implementation Best Practices
- Always extend base classes rather than modifying core framework
- Test with both `example1` and `freecell` projects
- Maintain backwards compatibility with existing JSON card data

#### 4. Quality Assurance
- Run both example scenes to verify functionality
- Check performance with large card collections
- Validate proper cleanup and memory management

## Key Configuration Areas

### CardManager Setup
- `card_size`: Default dimensions for all cards
- `card_factory_scene`: Factory responsible for card creation
- `debug_mode`: Enable visual debugging for drop zones

### CardFactory Configuration  
- `card_asset_dir`: Location of card image assets
- `card_info_dir`: Directory containing JSON card definitions
- `back_image`: Default card back texture

### JSON Card Schema
```json
{
    "name": "card_identifier",
    "front_image": "texture_filename.png",
    "suit": "optional_game_data",
    "value": "additional_properties"
}
```

## Common Implementation Patterns

### Card Movement and Animation
- Use `card.move(target_position, rotation)` for programmatic movement
- Leverage `moving_speed` property for consistent animation timing
- Handle movement completion via `on_card_move_done()` callbacks

### Game Rules Implementation
- Override `check_card_can_be_dropped()` in custom containers
- Use `move_cards()` with history tracking for undo/redo support
- Implement game state validation in container logic

### Performance Optimization
- Preload card data using `factory.preload_card_data()`
- Limit visual card display with `max_stack_display` in Pile containers
- Use `debug_mode` to identify performance bottlenecks

## Integration Points

### Asset Pipeline
- Card images in `card_asset_dir` (typically PNG format)
- JSON metadata in `card_info_dir` matching image filenames
- Support for Kenney.nl asset packs (included in examples)

### Scene Structure
- CardManager as root node in card-enabled scenes
- CardContainers as children of CardManager
- Cards instantiated dynamically via factory pattern

### Extensibility Hooks
- Virtual methods in CardContainer for custom behavior
- Card property extensions via inheritance
- Factory pattern for alternative card creation strategies

## Task Master AI Integration

This project includes Task Master AI for advanced project management:

```bash
# Initialize task tracking
task-master init

# Create tasks from project requirements
task-master parse-prd .taskmaster/docs/prd.txt

# Track development progress
task-master next    # Get next task
task-master show <id>    # View task details
task-master set-status --id=<id> --status=done
```

See `.taskmaster/CLAUDE.md` for detailed Task Master workflows.

## Troubleshooting Guide

### Common Issues
- **Cards not appearing**: Check `card_asset_dir` path and file naming
- **JSON loading errors**: Verify JSON syntax and required fields
- **Drag-and-drop issues**: Ensure CardContainer has `enable_drop_zone = true`
- **Performance problems**: Use `debug_mode` to visualize sensor areas

### Debug Tools
- Enable `debug_mode` in CardManager for visual debugging
- Use Godot's remote inspector for runtime state examination
- Check console output for framework-specific error messages

---

*This project demonstrates professional Godot addon development with comprehensive documentation, clean architecture, and production-ready examples. It serves as an excellent foundation for 2D card game development.*

## Task Master AI Instructions
**Import Task Master's development workflow commands and guidelines, treat as if import is in the main CLAUDE.md file.**
@./.taskmaster/CLAUDE.md
