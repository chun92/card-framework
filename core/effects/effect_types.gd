class_name EffectTypes
extends RefCounted
## The closed set of parameter types used by functions and atomic effects (Design Document 7.2).

const INT := "int"
const ENERGY_TYPE := "energy_type"
const ENERGY_TYPE_OR_ANY := "energy_type_or_any"
const POKEMON := "pokemon"
const PLAYER := "player"

const ALL := [INT, ENERGY_TYPE, ENERGY_TYPE_OR_ANY, POKEMON, PLAYER]
## Types a card effect can pass as a literal. Pokemon and players only exist during a match.
const LITERAL := [INT, ENERGY_TYPE, ENERGY_TYPE_OR_ANY]

const ANY_ENERGY := "Any"
const ENERGY_TYPES := ["Grass", "Fire", "Water", "Lightning", "Psychic", "Fighting", "Colorless"]

const SELF := "$self"
const DEFENDER := "$defender"
const PLAYER_REF := "$player"
const OPPONENT := "$opponent"
const CONTEXT := {
	SELF: POKEMON,
	DEFENDER: POKEMON,
	PLAYER_REF: PLAYER,
	OPPONENT: PLAYER,
}


static func is_known(type: String) -> bool:
	return ALL.has(type)


static func is_reference(value: Variant) -> bool:
	return value is String and (value as String).begins_with("$")


static func literal_matches(type: String, value: Variant) -> bool:
	match type:
		INT:
			return value is int or (value is float and is_equal_approx(value as float, roundf(value as float)))
		ENERGY_TYPE:
			return value is String and ENERGY_TYPES.has(value)
		ENERGY_TYPE_OR_ANY:
			return value is String and (ENERGY_TYPES.has(value) or value == ANY_ENERGY)
	return false


## Whether a value of type from can be passed where type to is declared.
static func assignable(from: String, to: String) -> bool:
	return from == to or (from == ENERGY_TYPE and to == ENERGY_TYPE_OR_ANY)


## True when a runtime value has the declared type.
static func runtime_matches(type: String, value: Variant) -> bool:
	match type:
		INT, ENERGY_TYPE, ENERGY_TYPE_OR_ANY:
			return literal_matches(type, value)
		POKEMON:
			return value is CardInPlay
		PLAYER:
			return value is PlayerState
	return false


## The value substituted at runtime for an invalid one, or null when the type has none.
static func neutral(type: String) -> Variant:
	if type == INT:
		return 0
	return null
