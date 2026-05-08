# Changelog

All notable changes to Card Framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4.0] - 2026-05-08

### Fixed
- **Card Return-to-Original Offset After Layout Shift**: Cards captured `original_destination` while the parent Container's deferred sort had not yet positioned the Pile/Hand, leaving the cache pinned to a transient (pre-sort) coordinate. After the sort, dragging a card and dropping it on an invalid zone returned the card to that stale location with a visible offset, most reproducibly when entering the card scene via `change_scene_to_file` from a separate main scene ([#38](https://github.com/chun92/card-framework/issues/38))
  - `Card.return_card` now asks the owning container for an on-demand target pose via the new `CardContainer.get_target_pose_for()` hook, so a returning card always lands at its current slot regardless of any layout shift since the card was last placed
  - `_assign_card_to_container` / `_insert_card_to_container` schedule a deferred layout-only reapply so cards added before the parent Container's sort settles get repositioned against the final layout
  - `DraggableObject.move()` now refreshes the cached "original" on its early-return branch so offset-zero cards (Pile bottom) don't get stuck with stale coordinates
- **Crash on Freed Card in `_held_cards`**: Defensive `_prune_freed_cards()` now drops invalid entries before each layout pass and the deferred reapply, so game code that calls `card.queue_free()` directly without a matching `remove_card()` no longer triggers a runtime error in downstream layout/state loops. Normal API flows already keep `_held_cards` consistent and are unaffected.

### Changed
- **BREAKING — `_update_target_positions` Split**: Card-state assignments (`show_front`, `can_be_interacted_with`) moved out of `_update_target_positions` into a new sibling virtual method `_update_card_states()`. `_update_target_positions` is now layout-only (positions, drop-zone geometry) and is the method called by the deferred reapply path. Custom containers that overrode `_update_target_positions` to ALSO assign card state must move that state code into a `_update_card_states()` override; pure-layout overrides are unaffected. See the **Migration Guide (1.3.x → 1.4.0)** below and `docs/API.md` for the updated abstract-method contract.
- **Coalesced Deferred Reapply**: Bulk `add_card()` flows (e.g. dealing 52 cards from a factory in `_ready`) now collapse to a single deferred layout pass per frame instead of N enqueued copies, dropping post-sort work from O(n²) to O(n) move() calls

### Added
- **`CardContainer.get_target_pose_for(card)` Hook**: Subclasses (Pile, Hand) implement this to compute the slot pose a held card SHOULD be at given the container's current state. Used by `Card.return_card` for layout-race-safe return; opt-in for custom containers (base returns `{}`, in which case `Card.return_card` falls back to the cached coordinate via `DraggableObject.return_to_original`).
- **`CardContainer._update_card_states()` Virtual Method**: Per-card display + interaction defaults. Override in containers that own these fields container-side; leave to the empty default if game code manages them externally.
- **Issue #38 Repro Harness**: `example1/repro_main.tscn` exposes three entry paths into example1 (immediate `change_scene_to_file`, after one process frame, and a forced layout-shift variant) for reproducing the bug and verifying regressions after future fixes.

### Migration Guide (1.3.x → 1.4.0)

The only breaking change is the `_update_target_positions` split. **In-tree subclasses (Pile, Hand, Tableau, Foundation, Freecell) are migrated**, so projects that only consume the framework via `Pile`/`Hand` or freecell-style subclasses need no code changes — just bump the version.

You only need to migrate if your project has a **custom CardContainer subclass** whose `_update_target_positions` override sets `card.show_front` or `card.can_be_interacted_with`. Move those assignments into a new `_update_card_states()` override:

```gdscript
# Before (1.3.x)
class_name MyContainer extends CardContainer

func _update_target_positions() -> void:
    for i in range(_held_cards.size()):
        var card = _held_cards[i]
        card.move(my_target_for(i), 0)
        card.show_front = true                # ← moves out
        card.can_be_interacted_with = true    # ← moves out

# After (1.4.0)
class_name MyContainer extends CardContainer

func _update_target_positions() -> void:
    for i in range(_held_cards.size()):
        _held_cards[i].move(my_target_for(i), 0)

func _update_card_states() -> void:
    for card in _held_cards:
        card.show_front = true
        card.can_be_interacted_with = true
```

**Why the split matters**: the deferred reapply path (added in 1.4.0 to fix #38) calls `_update_target_positions` *only*. If state assignments stayed in that method, the deferred pass would stomp on game-managed interaction state every frame after the parent Container's sort settles — exactly the kind of bug that breaks games like Freecell where tableau interactability is decided by stacking rules, not container defaults.

If your override only does layout (positions, drop-zone math), no migration is needed.

#### Optional: opt-in `get_target_pose_for(card)` for layout-race-safe return

`Card.return_card` now queries the owning container for an on-demand slot pose so a returning card lands at its current slot regardless of any layout shift since the card was last placed. The base implementation returns `{}` and `Card.return_card` falls back to the cached coordinate, so custom subclasses that don't implement this hook continue to work exactly as in 1.3.x — they just won't benefit from the #38 fix in scenarios where the container is repositioned by a parent Godot `Container` (or window resize, dynamic re-layout, etc.) after cards are placed.

To opt in, implement `get_target_pose_for(card: Card) -> Dictionary`. Return `{"position": Vector2, "rotation": float}` for held cards, or `{}` for unknown cards. The math should mirror what your `_update_target_positions` would produce for that card's index given the container's current state:

```gdscript
class_name MyContainer extends CardContainer

func get_target_pose_for(card: Card) -> Dictionary:
    var idx = _held_cards.find(card)
    if idx == -1:
        return {}
    return {
        "position": global_position + my_offset_for(idx),
        "rotation": 0.0,
    }
```

Recommended whenever the container is laid out by a parent Godot `Container` node, because the layout-race that motivated #38 applies to every such case — not just `Pile`/`Hand`.

## [1.3.4] - 2026-05-06

### Fixed
- **Hand Anchor Offset**: `hand_anchor` modes (CENTER/LEFT/RIGHT) now correctly align the layout box to `global_position` ([#31](https://github.com/chun92/card-framework/issues/31))
  - The fan is laid out inside a fixed layout box of width `max_hand_spread + card_w`; `hand_anchor` only chooses where this box sits relative to `global_position`. Card distribution inside the box is identical across modes, so cards always grow symmetrically about the box's center as the hand count changes.
- **Empty Hand Drop Zone**: Drop zone sensor for an empty hand now matches the full layout box, so the sensor area no longer jumps when the first card is added.
- **Card Position Not Reset on Self-Swap**: `Hand.swap_card()` now calls `update_card_ui()` before the early return when a card is dropped on its own slot, so the card animates back to its original position instead of staying where the cursor released it ([#32](https://github.com/chun92/card-framework/issues/32))
- **Drop Zones When Reordering Without Swap**: `Hand` now uses insert-slot partitions (between cards) when `swap_only_on_reorder` is `false`, and swap-target partitions (on each card) only when `true`. `move_cards()` adjusts the target index for the post-removal insertion so cards land where the user expects, and the rightmost insert slot (index == N) is no longer dropped ([#33](https://github.com/chun92/card-framework/issues/33))
- **Card Not Selectable After Reordering**: `cards_node` child order is now kept in sync with `_held_cards` via a new `_reorder_card_nodes()` helper called from `update_card_ui()`. Sibling order now matches visual order, so cards are always pickable regardless of reorder history ([#30](https://github.com/chun92/card-framework/issues/30))
  - Community contribution by [@tarnung](https://github.com/tarnung)

### Changed
- **`hand_anchor` Documentation**: Clarified the layout-box anchor contract in API docs and inline doc-comments. Anchor refers to the layout box, not to the post-rotation bbox; with strongly asymmetric rotation/vertical curves the post-rotation bbox can drift slightly from the box.
- **CLAUDE.md**: Streamlined contributor guide and aligned content with the current framework state.

## [1.3.3] - 2026-04-18

### Added
- **Editor Preview for CardContainers**: `Pile` and `Hand` now display preview rectangles in the Godot editor without running the scene ([#28](https://github.com/chun92/card-framework/issues/28))
  - Preview updates live when `card_size` (CardManager), `max_hand_spread`, or `hand_anchor` is changed in the Inspector
  - `Hand` preview reflects the full expected hand area based on `max_hand_spread` and `hand_anchor`
- **HandAnchor Enum**: New `hand_anchor` property on `Hand` container for flexible layout alignment
  - `CENTER` (default): node position is the center of the hand spread
  - `LEFT`: node position is the left edge of the hand spread
  - `RIGHT`: node position is the right edge of the hand spread
- **`DEBUG_PREVIEW_COLOR` Constant**: Added to `CardFrameworkSettings` for consistent editor preview styling

### Fixed
- **Card Size Not Applying in Godot 4.6**: `TextureRect.expand_mode` now explicitly set to `EXPAND_IGNORE_SIZE`, resolving an issue where cards could not shrink below the asset's natural dimensions ([#9](https://github.com/chun92/card-framework/issues/9))
- **Card Position Offset with Container Nodes**: `update_card_ui` is now deferred in `_ready()` so positions are calculated after Godot Container nodes finalize their layout 
- **Wrong Card Positions Outside CardManager Hierarchy**: `Hand` drop zone sensor now uses `global_position` instead of local `position`, fixing incorrect calculations when `Hand` is nested in Container nodes ([#29](https://github.com/chun92/card-framework/pull/29))

### Changed
- **`max_hand_spread` Clarification**: Property description updated to clarify it defines the position range between leftmost and rightmost card top-left corners; actual visual width is wider by approximately one card width
- **example1 Scene**: Reorganized to use `HBoxContainer`/`VBoxContainer` hierarchy, demonstrating flexible layout with CardContainers outside the CardManager tree

## [1.3.2] - 2026-02-15

### Changed
- **Godot Version Requirement**: Updated minimum version from 4.5 to 4.6
- **Project Cleanup**: Removed Task Master AI integration for streamlined project structure

## [1.3.1] - 2025-01-11

### Added
- **Asset Library Optimization**: Configured `.gitattributes` to distribute addon only (~90% size reduction) ([#27](https://github.com/chun92/card-framework/issues/27))
- **Addon Documentation**: Added LICENSE and README.md in addon folder per Godot guidelines
- **Release Scripts**: Automated full project archive creation (`scripts/create-release.sh` and `.ps1`)

### Changed
- Asset Library downloads now include only `addons/` folder; full project available via GitHub Releases
- Added `.gdignore` to prevent Godot importing screenshots

## [1.3.0] - 2025-01-10

### Added
- **Flexible CardContainer Layout System**: CardContainers can now be placed anywhere in scene tree hierarchy without requiring direct parent-child relationship with CardManager ([#25](https://github.com/chun92/card-framework/issues/25))
- **Custom Card Scene Support**: Flexible TextureRect assignment with `@export` variables for custom card scene structures
- **Scene Root Meta Registration**: Automatic CardManager discovery using tree traversal for complex UI hierarchies

### Changed
- **BREAKING**: CardManager must now be positioned **above** all CardContainers in scene tree hierarchy (no longer requires direct parent relationship)
- **Godot Version Requirement**: Minimum version updated from 4.4 to 4.5
- **Card TextureRect Properties**: `front_face_texture` and `back_face_texture` changed from `@onready` to `@export` with automatic fallback to hardcoded paths

### Fixed
- **Card Initialization**: Resolved `@export` setter null reference issue when instantiating card scenes with custom node structures ([#26](https://github.com/chun92/card-framework/issues/26))
- **FreeCell Game**: Prevented card dragging during game initialization by adding dual-layer protection against premature user interaction

### Improved
- **Documentation**: Comprehensive updates to README, GETTING_STARTED, and API documentation reflecting flexible layout system

## [1.2.3] - 2025-09-23

### Fixed
- **Mouse Interaction**: Fixed "dead cards" bug where rapid clicks made cards unresponsive ([#22](https://github.com/chun92/card-framework/issues/22))

## [1.2.2] - 2025-08-23

### Added
- **CardContainer API**: Added `get_card_count()` method to return the number of cards in a container

### Fixed
- **CardFactory Configuration**: Set proper JsonCardFactory defaults in `card_factory.tscn`

### Improved
- **Documentation**: Enhanced API reference with missing methods and corrected code examples
- **Getting Started**: Fixed code formatting and updated examples to use current API patterns
- **Code Examples**: Standardized API usage across all documentation and README files

### Contributors
- **Community**: Documentation improvements by @psin09

## [1.2.1] - 2025-08-19

### Refactored
- **DraggableObject API Enhancement**: Added `return_to_original()` method to base class for improved code reusability
- **Card API Simplification**: `Card.return_card()` now uses inherited `return_to_original()` wrapper pattern for better maintainability

## [1.2.0] - 2025-08-14

### Added
- **CardFrameworkSettings**: Centralized configuration constants for all framework values
- **State Machine System**: Complete rewrite of DraggableObject with robust state management
- **Tween Animation System**: Smooth, interruptible animations replacing _process-based movement
- **Precise Undo System**: Index-based undo with adaptive algorithm for correct card ordering
- **Comprehensive Documentation**: Full GDScript style guide compliance with detailed API docs

### Changed  
- **BREAKING**: `CardContainer.undo()` method signature now includes optional `from_indices` parameter
- **Magic Numbers**: All hardcoded values replaced with `CardFrameworkSettings` constants
- **Animation System**: All movement and hover effects now use Tween-based animations
- **State Management**: Drag-and-drop interactions now use validated state machine transitions
- **Memory Management**: Improved Tween resource cleanup preventing memory leaks

### Fixed
- **Multi-Card Undo Ordering**: Resolved card sequence corruption when undoing consecutive multi-card moves
- **Tween Memory Leaks**: Proper cleanup of animation resources in DraggableObject
- **Mouse Interaction**: Resolved various mouse control issues after card movements
- **Hover Animation**: Fixed scale accumulation bug preventing proper hover reset
- **Z-Index Management**: Foundation cards maintain proper z-index after auto-move completion
- **Hand Reordering**: Optimized internal reordering to prevent card position drift

### Developer Experience
- **MCP Integration**: Added Claude Code and TaskMaster AI integration for development workflow
- **Documentation Tools**: Custom Claude commands for automated documentation sync
- **Code Quality**: Applied comprehensive GDScript style guide with detailed method documentation

## [1.1.3] - 2025-07-10

### Added
- **Debug Mode**: Visual debugging support in `CardManager` with `debug_mode` flag
- **Drop Zone Visualization**: Reference guides matching Sensor Drop Zone size for debugging
- **Swap Reordering**: `swap_only_on_reorder` flag in `Hand` for alternative card reordering behavior

### Changed
- **Reordering Behavior**: `Hand` now supports both shifting (default) and swapping modes
- **History Optimization**: Moves within the same `CardContainer` no longer recorded in history

### Deprecated
- `sensor_visibility` property in `CardContainer` (use `debug_mode` in `CardManager`)
- `sensor_texture` property in `CardContainer` (replaced by automatic debug visualization)

### Fixed
- **Mouse Control**: Resolved inconsistent mouse control when adding cards to `CardContainer` at specific index
- **Performance**: Improved reliability of card positioning and interaction handling

## [1.1.2] - 2025-06-20

### Added
- **DraggableObject System**: Separated drag-and-drop functionality from `Card` class
- **Enhanced DropZone**: `accept_type` property for broader compatibility beyond `CardContainer`
- **Runtime Drop Zone Control**: Dynamic enable/disable of drop zones during gameplay

### Changed
- **Architecture**: Drag-and-drop now inheritable by any object via `DraggableObject`
- **Flexibility**: `DropZone` usable for non-card objects with type filtering

### Fixed
- **Hand Reordering**: Cards in full `Hand` containers can now be properly reordered
- **Drop Zone Reliability**: Improved drop zone detection and interaction handling

## [1.1.1] - 2025-06-06

### Fixed
- **Card Sizing**: Critical fix for `card_size` property not applying correctly
- **Visual Consistency**: Cards now properly respect configured size settings

## [1.1.0] - 2025-06-02

### Added
- **Enhanced Hand Functionality**: Card reordering within hands via drag-and-drop
- **JsonCardFactory**: Separated card creation logic for better extensibility
- **Improved Architecture**: Generic `CardFactory` base class for custom implementations

### Changed
- **Factory Pattern**: Refactored card creation system with abstract `CardFactory`
- **Drop Zone Logic**: Significantly improved drop zone handling and reliability
- **Code Organization**: Better separation of concerns between factory types

### Improved
- **Extensibility**: Easier to create custom card factories for different data sources
- **Reliability**: More robust card movement and container interactions

## [1.0.0] - 2025-01-03

### Added
- **Initial Release**: Complete Card Framework for Godot 4.x
- **Core Classes**: `CardManager`, `Card`, `CardContainer`, `Pile`, `Hand`
- **Drag & Drop System**: Intuitive card interactions with validation
- **JSON Card Support**: Data-driven card creation and configuration
- **Sample Projects**: `example1` demonstration and complete `freecell` game
- **Flexible Architecture**: Extensible base classes for custom game types

### Features
- **Card Management**: Creation, movement, and lifecycle management
- **Container System**: Specialized containers for different card layouts
- **Visual System**: Animations, hover effects, and visual feedback  
- **Game Logic**: Move history, undo functionality, and rule validation
- **Asset Integration**: Image loading and JSON data parsing

---

## Version Support

| Version | Godot Support | Status |
|---------|---------------|--------|
| 1.3.x   | 4.6+         | Active |
| 1.1.x   | 4.4+         | Legacy |
| 1.0.x   | 4.0-4.3      | Legacy |

## Upgrade Guide

### 1.2.x → 1.3.0

**Scene Hierarchy Changes:**
- Ensure CardManager is positioned above all CardContainers in scene tree
- No code changes required - existing direct parent-child setups remain fully compatible
- Optional: Reorganize CardContainers into complex UI structures as needed

**Custom Card Scenes:**
- Existing card scenes work without modification (automatic fallback)
- Optional: Assign custom TextureRect nodes via Inspector for non-standard structures

**Example Migration:**
```gdscript
# Old (still works)
Main → CardManager → Hand

# New (also works)
Main → CardManager
Main → UI → VBoxContainer → Hand ✅
```

**Invalid Layout (will not work):**
```gdscript
Main → VBoxContainer → CardManager → Hand ❌
```

### 1.1.2 → 1.1.3
- **Optional**: Enable `debug_mode` in `CardManager` for development
- **Deprecated**: Update any usage of `sensor_visibility` and `sensor_texture`
- **New Feature**: Consider `swap_only_on_reorder` for different hand behavior

### 1.1.1 → 1.1.2  
- **Breaking**: Review custom drag-and-drop implementations
- **Migration**: Update to use `DraggableObject` base class if extending drag functionality
- **Enhancement**: Utilize new `accept_type` in `DropZone` for type filtering

### 1.1.0 → 1.1.1
- **Fix**: No code changes required, automatic improvement for card sizing

### 1.0.x → 1.1.0
- **Migration**: Update `CardFactory` references to `JsonCardFactory` if using custom factories
- **Enhancement**: Take advantage of improved hand reordering functionality
- **Testing**: Verify drop zone interactions work correctly with improvements

## Contributing

See [Contributing Guidelines](../README.md#contributing) for information on reporting issues and contributing improvements.

## License

This project is open source. See [License](../README.md#license--credits) for details.