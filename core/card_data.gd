class_name CardData
extends RefCounted
## One physical card. Field values use TCGdex vocabulary ("Pokemon", "Basic", "Fighting").
## Built by TcgdexParser; never edited after construction.

const CATEGORY_POKEMON := "Pokemon"
const CATEGORY_TRAINER := "Trainer"
const CATEGORY_ENERGY := "Energy"
const STAGE_BASIC := "Basic"
const ENERGY_NORMAL := "Normal"
const ENERGY_SPECIAL := "Special"

var id: String = ""
var local_id: String = ""
var set_id: String = ""
var name: String = ""
var category: String = ""
var rarity: String = ""
## Base URL without quality or extension, e.g. https://assets.tcgdex.net/en/base/base1/52
var image_url: String = ""

# Pokemon
var stage: String = ""
var evolve_from: String = ""
var hp: int = 0
var types: Array[String] = []
var weakness_types: Array[String] = []
var weakness_modifier: String = ""
var resistance_types: Array[String] = []
var resistance_modifier: String = ""
var retreat_cost: int = 0
var attacks: Array[AttackData] = []
var powers: Array[PowerData] = []

# Trainer cards and Special Energy
var effect_text: String = ""

# Energy
var energy_kind: String = ""
var provides: Array[String] = []


func is_pokemon() -> bool:
	return category == CATEGORY_POKEMON


func is_basic_pokemon() -> bool:
	return is_pokemon() and stage == STAGE_BASIC


func is_trainer() -> bool:
	return category == CATEGORY_TRAINER


func is_energy() -> bool:
	return category == CATEGORY_ENERGY
