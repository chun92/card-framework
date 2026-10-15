class_name EffectContext
extends RefCounted
## What a resolving effect can see: the engine, the context values of Design Document 7.3,
## and the player's choice in progress (7.6).

const KIND_ATTACK := "attack"
const KIND_POWER := "power"
const KIND_TRAINER := "trainer"

## Returned by an atomic effect that needs a player's choice before it can finish.
const PENDING := "__pending_choice__"

var engine: MatchEngine
var kind: String = KIND_ATTACK
## The Pokemon whose attack or Power is resolving. Null for Trainers.
var source: CardInPlay
var defender: CardInPlay
var player: PlayerState
var opponent: PlayerState
## The attack being resolved. Null unless kind is attack.
var attack: AttackData

## The open question, or empty: {"prompt": String, "options": [{"label": String, "value": Variant}]}.
var choice: Dictionary = {}
## Answers given so far to the step currently resolving. Cleared when the step finishes.
var selection: Array = []


func value_of(ref_name: String) -> Variant:
	match ref_name:
		EffectTypes.SELF:
			return source
		EffectTypes.DEFENDER:
			return defender
		EffectTypes.PLAYER_REF:
			return player
		EffectTypes.OPPONENT:
			return opponent
	return null


func is_waiting() -> bool:
	return not choice.is_empty()


func ask(prompt: String, options: Array) -> String:
	choice = {"prompt": prompt, "options": options}
	return PENDING
