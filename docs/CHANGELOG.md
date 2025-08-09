# Changelog

All notable changes to Card Framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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