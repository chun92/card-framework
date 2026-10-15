class_name TcgdexParser
extends RefCounted
## Converts TCGdex card objects into CardData. Pure logic: no file access.
##
## TCGdex conventions this parser relies on, verified against Base Set, Jungle and Fossil:
##   - Every number arrives as a float (Godot's JSON parser).
##   - "retreat" is omitted when the retreat cost is 0.
##   - "weaknesses" and "resistances" are omitted when the card has none, and list one
##     entry per type: {"type": "Psychic", "value": "×2"}. Weakness uses the × sign.
##   - Attack "damage" is omitted, a number, or a string such as "10+", "30x", "50-" or "?".
##   - Basic Energy cards do not say what they provide. It is derived from the name.
##   - Special Energy states what it provides in its text: "Provides {C}{C} energy."
##   - "abilities" holds Pokemon Powers, with type "Pokemon Power".
##   - Trainer cards carry their text in "effect". Some, like Clefairy Doll, also print HP;
##     they are still Trainer cards.

const DAMAGE_SUFFIXES := ["+", "x", "×", "-", "?"]
const BASIC_ENERGY_NAME_SUFFIX := " Energy"
const ENERGY_TYPES := ["Grass", "Fire", "Water", "Lightning", "Psychic", "Fighting", "Colorless"]
## Energy symbols as TCGdex writes them in Special Energy text, e.g. "Provides {C}{C} energy."
const ENERGY_SYMBOLS := {
	"G": "Grass", "R": "Fire", "W": "Water", "L": "Lightning", "P": "Psychic", "F": "Fighting", "C": "Colorless",
}

## Problems that make a card unusable. parse() returns null when it adds one.
var errors: Array[String] = []
## Problems that leave the card usable but incomplete.
var warnings: Array[String] = []


func clear_messages() -> void:
	errors.clear()
	warnings.clear()


func parse(raw: Dictionary) -> CardData:
	var card := CardData.new()
	card.id = str(raw.get("id", ""))
	if card.id.is_empty():
		errors.append("card without id")
		return null

	var error_count := errors.size()
	card.local_id = str(raw.get("localId", ""))
	card.name = _required_string(raw, "name", card.id)
	card.category = _required_string(raw, "category", card.id)
	card.rarity = str(raw.get("rarity", ""))
	card.image_url = str(raw.get("image", ""))
	var set_ref: Variant = raw.get("set")
	if set_ref is Dictionary:
		card.set_id = str((set_ref as Dictionary).get("id", ""))

	match card.category:
		CardData.CATEGORY_POKEMON:
			_parse_pokemon(raw, card)
		CardData.CATEGORY_TRAINER:
			card.effect_text = str(raw.get("effect", ""))
			# Clefairy Doll and Mysterious Fossil print HP; they remain Trainer cards.
			card.hp = int(raw.get("hp", 0))
		CardData.CATEGORY_ENERGY:
			_parse_energy(raw, card)
		"":
			pass
		_:
			errors.append("%s: unknown category '%s'" % [card.id, card.category])

	return card if errors.size() == error_count else null


func _parse_pokemon(raw: Dictionary, card: CardData) -> void:
	card.stage = _required_string(raw, "stage", card.id)
	card.evolve_from = str(raw.get("evolveFrom", ""))

	if not raw.has("hp"):
		errors.append("%s: Pokemon without hp" % card.id)
	card.hp = int(raw.get("hp", 0))

	card.types.assign(_string_array(raw.get("types"), card.id, "types"))
	if card.types.is_empty():
		errors.append("%s: Pokemon without types" % card.id)

	var weakness := _group_modifiers(raw.get("weaknesses"), card.id, "weaknesses")
	card.weakness_types.assign(weakness["types"] as Array)
	card.weakness_modifier = str(weakness["modifier"])

	var resistance := _group_modifiers(raw.get("resistances"), card.id, "resistances")
	card.resistance_types.assign(resistance["types"] as Array)
	card.resistance_modifier = str(resistance["modifier"])

	# TCGdex omits "retreat" when the cost is 0.
	card.retreat_cost = int(raw.get("retreat", 0))

	for attack_value: Variant in _array(raw.get("attacks"), card.id, "attacks"):
		var attack := _parse_attack(attack_value, card.id)
		if attack != null:
			card.attacks.append(attack)

	for power_value: Variant in _array(raw.get("abilities"), card.id, "abilities"):
		if not power_value is Dictionary:
			errors.append("%s: ability is not an object" % card.id)
			continue
		var power_raw := power_value as Dictionary
		var power := PowerData.new()
		power.name = _required_string(power_raw, "name", card.id)
		power.kind = str(power_raw.get("type", ""))
		power.effect_text = str(power_raw.get("effect", ""))
		card.powers.append(power)

	if card.attacks.is_empty() and card.powers.is_empty():
		warnings.append("%s: Pokemon with neither attacks nor powers" % card.id)


func _parse_attack(value: Variant, card_id: String) -> AttackData:
	if not value is Dictionary:
		errors.append("%s: attack is not an object" % card_id)
		return null
	var raw := value as Dictionary
	var attack := AttackData.new()
	attack.name = _required_string(raw, "name", card_id)
	attack.effect_text = str(raw.get("effect", ""))

	if raw.has("cost"):
		attack.cost.assign(_string_array(raw["cost"], card_id, "attack cost"))
	else:
		warnings.append("%s: attack '%s' has no cost field; treated as free" % [card_id, attack.name])

	var damage: Variant = raw.get("damage")
	if damage == null:
		attack.damage = 0
	elif damage is float or damage is int:
		attack.damage = int(damage)
	elif damage is String:
		var text := (damage as String).strip_edges()
		if not text.is_empty() and DAMAGE_SUFFIXES.has(text.right(1)):
			attack.damage_suffix = text.right(1)
			text = text.left(-1)
		if text.is_empty():
			attack.damage = 0
		elif text.is_valid_int():
			attack.damage = text.to_int()
		else:
			errors.append("%s: attack '%s' has unreadable damage '%s'" % [card_id, attack.name, damage])
	else:
		errors.append("%s: attack '%s' has damage of unexpected type" % [card_id, attack.name])

	return attack


func _parse_energy(raw: Dictionary, card: CardData) -> void:
	card.energy_kind = _required_string(raw, "energyType", card.id)
	card.effect_text = str(raw.get("effect", ""))

	match card.energy_kind:
		CardData.ENERGY_NORMAL:
			var energy_type := card.name.trim_suffix(BASIC_ENERGY_NAME_SUFFIX)
			if energy_type == card.name or not ENERGY_TYPES.has(energy_type):
				errors.append("%s: cannot derive the type of Basic Energy '%s'" % [card.id, card.name])
				return
			card.provides.append(energy_type)
		CardData.ENERGY_SPECIAL:
			card.provides.assign(_provided_symbols(card.effect_text))
			if card.provides.is_empty():
				warnings.append("%s: %s is Special Energy and its text does not say what it provides" % [card.id, card.name])
		"":
			pass
		_:
			errors.append("%s: unknown energyType '%s'" % [card.id, card.energy_kind])


## Reads "Provides {C}{C} energy." into ["Colorless", "Colorless"]. Empty when the text does not match.
func _provided_symbols(text: String) -> Array[String]:
	var result: Array[String] = []
	var pattern := RegEx.create_from_string("^Provides ((?:\\{[A-Z]\\})+) [Ee]nergy")
	var found := pattern.search(text)
	if found == null:
		return result
	for symbol in RegEx.create_from_string("\\{([A-Z])\\}").search_all(found.get_string(1)):
		var letter := symbol.get_string(1)
		if not ENERGY_SYMBOLS.has(letter):
			return []
		result.append(str(ENERGY_SYMBOLS[letter]))
	return result


## Turns [{"type": "Psychic", "value": "×2"}, ...] into {"types": [...], "modifier": "×2"}.
func _group_modifiers(value: Variant, card_id: String, field: String) -> Dictionary:
	var types: Array[String] = []
	var modifier := ""
	for entry_value: Variant in _array(value, card_id, field):
		if not entry_value is Dictionary:
			errors.append("%s: %s entry is not an object" % [card_id, field])
			continue
		var entry := entry_value as Dictionary
		var entry_modifier := str(entry.get("value", ""))
		if modifier.is_empty():
			modifier = entry_modifier
		elif entry_modifier != modifier:
			errors.append("%s: %s with different values (%s, %s) do not fit the shared-modifier schema" % [card_id, field, modifier, entry_modifier])
		types.append(str(entry.get("type", "")))
	return {"types": types, "modifier": modifier}


func _required_string(raw: Dictionary, key: String, card_id: String) -> String:
	var value := str(raw.get(key, ""))
	if value.is_empty():
		errors.append("%s: missing %s" % [card_id, key])
	return value


func _array(value: Variant, card_id: String, field: String) -> Array:
	if value == null:
		return []
	if not value is Array:
		errors.append("%s: %s is not an array" % [card_id, field])
		return []
	return value as Array


func _string_array(value: Variant, card_id: String, field: String) -> Array[String]:
	var result: Array[String] = []
	for item: Variant in _array(value, card_id, field):
		result.append(str(item))
	return result
