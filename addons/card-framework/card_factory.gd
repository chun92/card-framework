@tool
## Abstract base class for card creation factories using the Factory design pattern.
##
## CardFactory defines the interface for creating cards in the card framework.
## Concrete implementations like JsonCardFactory provide specific card creation
## logic while maintaining consistent behavior across different card types and
## data sources.
##
## Design Pattern: Factory Method
## This abstract factory allows the card framework to create cards without
## knowing the specific implementation details. Different factory types can
## support various data sources (JSON files, databases, hardcoded data, etc.).
##
## Key Responsibilities:
## - Define card creation interface for consistent behavior
## - Manage card data caching for performance optimization
## - Provide card size configuration for uniform scaling
## - Support preloading mechanisms for reduced runtime I/O
##
## Subclass Implementation Requirements:
## - Override create_card() to implement specific card creation logic
## - Override preload_card_data() to implement data initialization
## - Use preloaded_cards dictionary for caching when appropriate
##
## Usage:
## [codeblock]
## class_name MyCardFactory
## extends CardFactory
##
## func create_card(card_name: String, target: CardContainer) -> Card:
##     # Implementation-specific card creation
##     return my_card_instance
## [/codeblock]
class_name CardFactory
extends Node

# Core factory data and configuration
## Dictionary cache for storing preloaded card data to improve performance
## Key: card identifier (String), Value: card data (typically Dictionary)
var preloaded_cards = {}

## Default size for cards created by this factory
## Applied to all created cards unless overridden
var card_size: Vector2


## Virtual method for creating a card instance and adding it to a container.
## Must be implemented by concrete factory subclasses to provide specific
## card creation logic based on the factory's data source and requirements.
## @param card_name: Identifier for the card to create
## @param target: CardContainer where the created card will be added
## @returns: Created Card instance or null if creation failed
func create_card(card_name: String, target: CardContainer) -> Card:
	return null


## Virtual method for preloading card data into the factory's cache.
## Concrete implementations should override this to load card definitions
## from their respective data sources (files, databases, etc.) into the
## preloaded_cards dictionary for faster card creation during gameplay.
func preload_card_data() -> void:
	pass
