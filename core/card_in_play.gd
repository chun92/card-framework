class_name CardInPlay
extends RefCounted

const COLORLESS := "Colorless"

var card: CardData
var damage: int = 0
var attached_energy: Array[CardData] = []
var turn_played: int = 0


func _init(played_card: CardData, played_on_turn: int) -> void:
	card = played_card
	turn_played = played_on_turn


func remaining_hp() -> int:
	return maxi(card.hp - damage, 0)


func is_knocked_out() -> bool:
	return damage >= card.hp


func energy_pool() -> Array[String]:
	var pool: Array[String] = []
	for energy in attached_energy:
		pool.append_array(energy.provides)
	return pool


## Typed requirements are matched first; Colorless is checked against what remains.
func can_pay(cost: Array[String]) -> bool:
	var pool := energy_pool()
	var colorless_needed := 0
	for requirement in cost:
		if requirement == COLORLESS:
			colorless_needed += 1
			continue
		var index := pool.find(requirement)
		if index == -1:
			return false
		pool.remove_at(index)
	return pool.size() >= colorless_needed


func retreat_cost() -> Array[String]:
	var cost: Array[String] = []
	for _i in card.retreat_cost:
		cost.append(COLORLESS)
	return cost


## Removes last-attached Energy cards until they provide at least units Energy, so a
## Double Colorless Energy pays two. Known divergence (4.8): the player does not choose.
func detach_energy_units(units: int) -> Array[CardData]:
	var removed: Array[CardData] = []
	var paid := 0
	while paid < units and not attached_energy.is_empty():
		var energy := attached_energy.pop_back() as CardData
		removed.append(energy)
		paid += maxi(energy.provides.size(), 1)
	return removed
