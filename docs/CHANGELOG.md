# Changelog

All notable changes to Card Framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

| Version | Godot Support | Status | EOL Date |
|---------|---------------|--------|----------|
| 1.1.x   | 4.4+         | Active | -        |
| 1.0.x   | 4.0-4.3      | Legacy | 2025-12-31 |

## Upgrade Guide

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