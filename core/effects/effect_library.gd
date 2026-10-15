class_name EffectLibrary
extends RefCounted
## Functions and card effects, validated at load (Design Document 7.7). Entries that fail
## validation are reported in errors and are never resolved: binding_for() does not return them.

const SECTION_ATTACKS := "attacks"
const SECTION_POWERS := "powers"
const SECTION_TRAINER := "trainer"
const SECTION_ENERGY := "energy"
const SECTIONS := [SECTION_ATTACKS, SECTION_POWERS, SECTION_TRAINER, SECTION_ENERGY]
const SECTION_KINDS := {
	SECTION_ATTACKS: EffectContext.KIND_ATTACK,
	SECTION_POWERS: EffectContext.KIND_POWER,
	SECTION_TRAINER: EffectContext.KIND_TRAINER,
	SECTION_ENERGY: EffectContext.KIND_TRAINER,
}
const FUNCTION_KEYS := ["params", "requires", "steps", "returns"]
const STEP_KEYS := ["call", "args", "as", "when"]
const BINDING_KEYS := ["function", "args"]
const COMPARISONS := ["eq", "ne", "gt", "gte", "lt", "lte"]

var errors: Array[String] = []
var warnings: Array[String] = []

var functions: Dictionary = {}

## card id -> section -> (printed name -> binding) for attacks and powers, or binding.
var _card_effects: Dictionary = {}
var _valid_bindings: Dictionary = {}
var _invalid_functions: Dictionary = {}
var _requires_cache: Dictionary = {}
var _attack_only_cache: Dictionary = {}
var _uses_self_cache: Dictionary = {}


func load_data(functions_document: Dictionary, card_effects_document: Dictionary, database: CardDatabase) -> void:
	errors.clear()
	warnings.clear()
	functions = functions_document
	_card_effects = card_effects_document
	_valid_bindings.clear()
	_invalid_functions.clear()
	_requires_cache.clear()
	_attack_only_cache.clear()
	_uses_self_cache.clear()

	for name: Variant in functions:
		if AtomicEffects.has(str(name)):
			_function_error(str(name), "the name is also an atomic effect")
		elif not functions[name] is Dictionary:
			_function_error(str(name), "definition is not an object")
		else:
			_validate_function(str(name), functions[name] as Dictionary)
	_validate_cycles()
	_propagate_invalid_functions()
	_validate_card_effects(database)


func function_count() -> int:
	return functions.size()


func valid_binding_count() -> int:
	return _valid_bindings.size()


## The validated {function, args} for a printed attack, Power, Trainer or Special Energy,
## or an empty Dictionary. name is ignored for the trainer and energy sections.
func binding_for(card_id: String, section: String, name: String) -> Dictionary:
	return _valid_bindings.get(_binding_key(card_id, section, name), {}) as Dictionary


func has_requirements(function_name: String) -> bool:
	if _requires_cache.has(function_name):
		return bool(_requires_cache[function_name])
	_requires_cache[function_name] = false
	var definition := functions.get(function_name, {}) as Dictionary
	var requires: Variant = definition.get("requires", [])
	var result := requires is Array and not (requires as Array).is_empty()
	for step in _steps(definition):
		var callee := str(step.get("call", ""))
		if functions.has(callee) and has_requirements(callee):
			result = true
	_requires_cache[function_name] = result
	return result


func is_attack_only(function_name: String) -> bool:
	if _attack_only_cache.has(function_name):
		return bool(_attack_only_cache[function_name])
	_attack_only_cache[function_name] = false
	var result := false
	for step in _steps(functions.get(function_name, {}) as Dictionary):
		var callee := str(step.get("call", ""))
		if AtomicEffects.is_attack_only(callee) or (functions.has(callee) and is_attack_only(callee)):
			result = true
	_attack_only_cache[function_name] = result
	return result


func uses_self(function_name: String) -> bool:
	if _uses_self_cache.has(function_name):
		return bool(_uses_self_cache[function_name])
	_uses_self_cache[function_name] = false
	var definition := functions.get(function_name, {}) as Dictionary
	var result := JSON.stringify(definition).contains("\"%s\"" % EffectTypes.SELF)
	for step in _steps(definition):
		var callee := str(step.get("call", ""))
		if functions.has(callee) and uses_self(callee):
			result = true
	_uses_self_cache[function_name] = result
	return result


func params_of(callee: String) -> Dictionary:
	if functions.has(callee):
		return (functions[callee] as Dictionary).get("params", {}) as Dictionary
	return AtomicEffects.params_of(callee)


func returns_of(callee: String) -> String:
	if functions.has(callee):
		var returns: Variant = (functions[callee] as Dictionary).get("returns")
		return str((returns as Dictionary).get("type", "")) if returns is Dictionary else ""
	return AtomicEffects.returns_of(callee)


# --- Functions --------------------------------------------------------------------------

func _validate_function(name: String, definition: Dictionary) -> void:
	for key: Variant in definition:
		if not FUNCTION_KEYS.has(key):
			_function_error(name, "unknown key '%s'" % key)

	var scope := {}
	var params: Variant = definition.get("params", {})
	if not params is Dictionary:
		_function_error(name, "params is not an object")
		params = {}
	for param: Variant in params as Dictionary:
		var type := str((params as Dictionary)[param])
		if str(param).begins_with("$") or not _is_identifier(str(param)):
			_function_error(name, "invalid parameter name '%s'" % param)
		if not EffectTypes.is_known(type):
			_function_error(name, "parameter '%s' has unknown type '%s'" % [param, type])
		scope[str(param)] = type

	var requires: Variant = definition.get("requires", [])
	if not requires is Array:
		_function_error(name, "requires is not a list")
		requires = []
	for requirement: Variant in requires as Array:
		if not requirement is Dictionary:
			_function_error(name, "a requirement is not an object")
			continue
		var check := str((requirement as Dictionary).get("check", ""))
		if AtomicEffects.role_of(check) != AtomicEffects.ROLE_CHECK:
			_function_error(name, "requirement '%s' is not a check" % check)
			continue
		_validate_args(name, "check '%s'" % check, (requirement as Dictionary).get("args"), AtomicEffects.params_of(check), scope, {}, false)

	var steps: Variant = definition.get("steps", [])
	if not steps is Array or (steps as Array).is_empty():
		_function_error(name, "steps must be a non-empty list")
		steps = []
	var outputs := {}
	for index in (steps as Array).size():
		var step_value: Variant = (steps as Array)[index]
		var where := "step %d" % (index + 1)
		if not step_value is Dictionary:
			_function_error(name, "%s is not an object" % where)
			continue
		_validate_step(name, where, step_value as Dictionary, scope, outputs)

	var returns: Variant = definition.get("returns")
	if returns != null:
		if not returns is Dictionary:
			_function_error(name, "returns is not an object")
		else:
			var value := str((returns as Dictionary).get("value", ""))
			var type := str((returns as Dictionary).get("type", ""))
			var known := _reference_type(value, scope, outputs)
			if known.is_empty():
				_function_error(name, "returns an undefined value '%s'" % value)
			elif not EffectTypes.assignable(known, type):
				_function_error(name, "returns '%s' of type %s, declared %s" % [value, known, type])


func _validate_step(name: String, where: String, step: Dictionary, scope: Dictionary, outputs: Dictionary) -> void:
	for key: Variant in step:
		if not STEP_KEYS.has(key):
			_function_error(name, "%s has unknown key '%s'" % [where, key])

	var callee := str(step.get("call", ""))
	var is_function := functions.has(callee)
	if not is_function and AtomicEffects.role_of(callee) != AtomicEffects.ROLE_EFFECT:
		_function_error(name, "%s calls '%s', which is neither a function nor an atomic effect" % [where, callee])
		return

	var conditional := step.has("when")
	var calls_requirements := is_function and has_requirements(callee)
	if conditional and calls_requirements:
		_function_error(name, "%s calls '%s', which has requirements, under when" % [where, callee])

	_validate_args(name, "%s ('%s')" % [where, callee], step.get("args"), params_of(callee), scope, outputs, calls_requirements)

	if conditional:
		_validate_condition(name, where, step["when"], scope, outputs)
		if step.has("as"):
			_function_error(name, "%s is conditional and may not publish an output" % where)
		return

	if step.has("as"):
		var output := str(step["as"])
		if not _is_identifier(output):
			_function_error(name, "%s publishes an invalid name '%s'" % [where, output])
		elif scope.has(output):
			_function_error(name, "%s output '%s' reuses a parameter name" % [where, output])
		elif outputs.has(output):
			_function_error(name, "%s output '%s' is already defined" % [where, output])
		var type := returns_of(callee)
		if type.is_empty():
			_function_error(name, "%s publishes '%s', but '%s' returns nothing" % [where, output, callee])
		outputs[output] = type


func _validate_args(owner: String, where: String, args_value: Variant, params: Dictionary, scope: Dictionary, outputs: Dictionary, no_outputs: bool) -> void:
	if not args_value is Dictionary:
		_function_error(owner, "%s has no args object" % where)
		return
	var args := args_value as Dictionary
	for param: Variant in params:
		if not args.has(param):
			_function_error(owner, "%s is missing argument '%s'" % [where, param])
	for arg: Variant in args:
		if not params.has(arg):
			_function_error(owner, "%s has extra argument '%s'" % [where, arg])
			continue
		var expected := str(params[arg])
		var value: Variant = args[arg]
		if EffectTypes.is_reference(value):
			if no_outputs and outputs.has(str(value).trim_prefix("$")):
				_function_error(owner, "%s passes output '%s' to a function with requirements" % [where, value])
			var actual := _reference_type(str(value), scope, outputs)
			if actual.is_empty():
				_function_error(owner, "%s argument '%s' refers to undefined '%s'" % [where, arg, value])
			elif not EffectTypes.assignable(actual, expected):
				_function_error(owner, "%s argument '%s' is %s, expected %s" % [where, arg, actual, expected])
		elif not EffectTypes.literal_matches(expected, value):
			_function_error(owner, "%s argument '%s' has a value that is not a valid %s" % [where, arg, expected])


func _validate_condition(name: String, where: String, condition_value: Variant, scope: Dictionary, outputs: Dictionary) -> void:
	if not condition_value is Dictionary:
		_function_error(name, "%s when is not an object" % where)
		return
	var condition := condition_value as Dictionary
	var value: Variant = condition.get("value")
	if EffectTypes.is_reference(value):
		var type := _reference_type(str(value), scope, outputs)
		if type != EffectTypes.INT:
			_function_error(name, "%s when compares '%s', which is not an int" % [where, value])
	elif not EffectTypes.literal_matches(EffectTypes.INT, value):
		_function_error(name, "%s when value is not an int" % where)
	var operators := 0
	for key: Variant in condition:
		if key == "value":
			continue
		if not COMPARISONS.has(key):
			_function_error(name, "%s when has unknown comparison '%s'" % [where, key])
		elif not EffectTypes.literal_matches(EffectTypes.INT, condition[key]):
			_function_error(name, "%s when compares against a non-int literal" % where)
		operators += 1
	if operators != 1:
		_function_error(name, "%s when needs exactly one comparison" % where)


func _reference_type(ref_name: String, scope: Dictionary, outputs: Dictionary) -> String:
	if EffectTypes.CONTEXT.has(ref_name):
		return str(EffectTypes.CONTEXT[ref_name])
	var name := ref_name.trim_prefix("$")
	if not ref_name.begins_with("$"):
		return ""
	if scope.has(name):
		return str(scope[name])
	if outputs.has(name):
		return str(outputs[name])
	return ""


func _validate_cycles() -> void:
	var state := {}  # 1 visiting, 2 done
	for name: Variant in functions:
		_visit(str(name), state, [])


func _visit(name: String, state: Dictionary, path: Array) -> void:
	if int(state.get(name, 0)) == 2:
		return
	if int(state.get(name, 0)) == 1:
		_function_error(name, "call cycle: %s" % " -> ".join(PackedStringArray(path + [name])))
		return
	state[name] = 1
	for step in _steps(functions.get(name, {}) as Dictionary):
		var callee := str(step.get("call", ""))
		if functions.has(callee):
			_visit(callee, state, path + [name])
	state[name] = 2


func _propagate_invalid_functions() -> void:
	var changed := true
	while changed:
		changed = false
		for name: Variant in functions:
			if _invalid_functions.has(name):
				continue
			for step in _steps(functions[name] as Dictionary):
				if _invalid_functions.has(str(step.get("call", ""))):
					_invalid_functions[name] = true
					changed = true
					break


# --- Card effects -----------------------------------------------------------------------

func _validate_card_effects(database: CardDatabase) -> void:
	var names_to_functions := {}
	for card_id: Variant in _card_effects:
		var id := str(card_id)
		if not database.has_card(id):
			errors.append("card_effects %s: no such card" % id)
			continue
		if not _card_effects[card_id] is Dictionary:
			errors.append("card_effects %s: entry is not an object" % id)
			continue
		var card := database.make(id)
		var entry := _card_effects[card_id] as Dictionary
		for section: Variant in entry:
			match str(section):
				SECTION_ATTACKS, SECTION_POWERS:
					if not entry[section] is Dictionary:
						errors.append("card_effects %s: %s is not an object" % [id, section])
						continue
					var printed := _printed_names(card, str(section))
					for printed_name: Variant in entry[section] as Dictionary:
						var where := "card_effects %s %s '%s'" % [id, section, printed_name]
						if not printed.has(printed_name):
							errors.append("%s: the card does not print it" % where)
							continue
						_validate_binding(where, id, str(section), str(printed_name), (entry[section] as Dictionary)[printed_name], names_to_functions)
				SECTION_TRAINER:
					if not card.is_trainer():
						errors.append("card_effects %s: trainer entry on a card that is not a Trainer" % id)
						continue
					_validate_binding("card_effects %s trainer" % id, id, SECTION_TRAINER, card.name, entry[section], names_to_functions)
				SECTION_ENERGY:
					if not (card.is_energy() and card.energy_kind == CardData.ENERGY_SPECIAL):
						errors.append("card_effects %s: energy entry on a card that is not Special Energy" % id)
						continue
					_validate_binding("card_effects %s energy" % id, id, SECTION_ENERGY, card.name, entry[section], names_to_functions)
				_:
					errors.append("card_effects %s: unknown section '%s'" % [id, section])

	for key: Variant in names_to_functions:
		var bound := (names_to_functions[key] as Dictionary).keys()
		if bound.size() > 1:
			bound.sort()
			warnings.append("%s is bound to different functions: %s" % [key, ", ".join(PackedStringArray(bound))])


func _validate_binding(where: String, card_id: String, section: String, printed_name: String, value: Variant, names_to_functions: Dictionary) -> void:
	if not value is Dictionary:
		errors.append("%s: binding is not an object" % where)
		return
	var binding := value as Dictionary
	var error_count := errors.size()
	for key: Variant in binding:
		if not BINDING_KEYS.has(key):
			errors.append("%s: unknown key '%s'" % [where, key])
	var function_name := str(binding.get("function", ""))
	if not functions.has(function_name):
		errors.append("%s: no function '%s'" % [where, function_name])
		return
	if _invalid_functions.has(function_name):
		errors.append("%s: function '%s' has errors" % [where, function_name])

	var kind := str(SECTION_KINDS[section])
	if kind != EffectContext.KIND_ATTACK and is_attack_only(function_name):
		errors.append("%s: function '%s' only works while an attack resolves" % [where, function_name])
	if kind == EffectContext.KIND_TRAINER and uses_self(function_name):
		errors.append("%s: function '%s' uses $self, which a Trainer does not have" % [where, function_name])

	var args: Variant = binding.get("args")
	if not args is Dictionary:
		errors.append("%s: args is not an object" % where)
		return
	var params := params_of(function_name)
	for param: Variant in params:
		if not (args as Dictionary).has(param):
			errors.append("%s: missing argument '%s'" % [where, param])
	for arg: Variant in args as Dictionary:
		if not params.has(arg):
			errors.append("%s: extra argument '%s'" % [where, arg])
			continue
		var type := str(params[arg])
		var arg_value: Variant = (args as Dictionary)[arg]
		if EffectTypes.is_reference(arg_value):
			errors.append("%s: argument '%s' is a reference; card effects take literal values only" % [where, arg])
		elif not EffectTypes.LITERAL.has(type):
			errors.append("%s: parameter '%s' of type %s cannot be passed by a card" % [where, arg, type])
		elif not EffectTypes.literal_matches(type, arg_value):
			errors.append("%s: argument '%s' is not a valid %s" % [where, arg, type])

	var name_key := "%s '%s'" % [section, printed_name]
	if not names_to_functions.has(name_key):
		names_to_functions[name_key] = {}
	(names_to_functions[name_key] as Dictionary)[function_name] = true

	if errors.size() == error_count:
		_valid_bindings[_binding_key(card_id, section, printed_name)] = binding


func _printed_names(card: CardData, section: String) -> Array[String]:
	var names: Array[String] = []
	if section == SECTION_ATTACKS:
		for attack in card.attacks:
			names.append(attack.name)
	else:
		for power in card.powers:
			names.append(power.name)
	return names


# --- Helpers ----------------------------------------------------------------------------

func _steps(definition: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var steps: Variant = definition.get("steps", [])
	if steps is Array:
		for step: Variant in steps as Array:
			if step is Dictionary:
				result.append(step as Dictionary)
	return result


func _binding_key(card_id: String, section: String, name: String) -> String:
	if section == SECTION_TRAINER or section == SECTION_ENERGY:
		return "%s/%s" % [card_id, section]
	return "%s/%s/%s" % [card_id, section, name]


func _function_error(name: String, message: String) -> void:
	errors.append("functions %s: %s" % [name, message])
	_invalid_functions[name] = true


func _is_identifier(text: String) -> bool:
	return text.is_valid_identifier()
