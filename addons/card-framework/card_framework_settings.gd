## Card Framework configuration constants class.
##
## This class provides centralized constant values for all Card Framework components
## without requiring Autoload. All values are defined as constants to ensure
## consistent behavior across the framework.
##
## Usage:
## [codeblock]
## # Reference constants directly
## var speed = CardFrameworkSettings.ANIMATION_MOVE_SPEED
## var z_offset = CardFrameworkSettings.VISUAL_DRAG_Z_OFFSET
## [/codeblock]
class_name CardFrameworkSettings
extends RefCounted

# Animation Constants
## Speed of card movement animations in pixels per second
const ANIMATION_MOVE_SPEED: float = 2000.0
## Duration of hover animations in seconds
const ANIMATION_HOVER_DURATION: float = 0.10
## Scale multiplier applied during hover effects
const ANIMATION_HOVER_SCALE: float = 1.1
## Rotation in degrees applied during hover effects  
const ANIMATION_HOVER_ROTATION: float = 0.0

# Physics & Interaction Constants
## Distance threshold for hover detection in pixels
const PHYSICS_HOVER_DISTANCE: float = 10.0
## Distance cards move up during hover in pixels
const PHYSICS_CARD_HOVER_DISTANCE: float = 30.0

# Visual Layout Constants
## Z-index offset applied to cards during drag operations
const VISUAL_DRAG_Z_OFFSET: int = 1000
## Z-index for pile cards to ensure proper layering
const VISUAL_PILE_Z_INDEX: int = 3000
## Z-index for drop zone sensors (below everything)
const VISUAL_SENSOR_Z_INDEX: int = -1000
## Z-index for debug outlines (above UI)
const VISUAL_OUTLINE_Z_INDEX: int = 1200

# Container Layout Constants
## Default card size used throughout the framework
const LAYOUT_DEFAULT_CARD_SIZE: Vector2 = Vector2(150, 210)
## Distance between stacked cards in piles
const LAYOUT_STACK_GAP: int = 8
## Maximum cards to display in stack before hiding
const LAYOUT_MAX_STACK_DISPLAY: int = 6
## Maximum number of cards in hand containers
const LAYOUT_MAX_HAND_SIZE: int = 10
## Maximum pixel spread for hand arrangements
const LAYOUT_MAX_HAND_SPREAD: int = 700

# Color Constants for Debugging
## Color used for sensor outlines and debug indicators
const DEBUG_OUTLINE_COLOR: Color = Color(1, 0, 0, 1)
