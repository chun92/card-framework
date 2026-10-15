class_name AttackData
extends RefCounted

var name: String = ""
var cost: Array[String] = []
## The number printed in the damage field. 0 when the attack prints no damage.
var damage: int = 0
## What is printed after the number: "", "+", "x", "-" or "?". Card effects resolve it.
var damage_suffix: String = ""
var effect_text: String = ""


## True when the printed damage alone does not describe the attack.
func has_effect() -> bool:
	return not effect_text.is_empty() or not damage_suffix.is_empty()
