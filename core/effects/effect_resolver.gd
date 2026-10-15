class_name EffectResolver
extends RefCounted
## Resolves validated functions against a match (Design Document 7.3 to 7.7).
##
## Resolution uses an explicit stack of frames instead of GDScript's call stack, so it can
## later be suspended for a player's choice and resumed from the next apply() (7.6).

var _library: EffectLibrary
var _context: EffectContext
var _stack: Array[Dictionary] = []


func _init(library: EffectLibrary, context: EffectContext) -> void:
	_library = library
	_context = context


## Evaluates requires, including those of every function it calls, with arguments bound.
func requirements_met(function_name: String, args: Dictionary) -> bool:
	var definition := _library.functions.get(function_name, {}) as Dictionary
	for requirement: Variant in definition.get("requires", []) as Array:
		var check := str((requirement as Dictionary)["check"])
		var bound: Variant = _bind(AtomicEffects.params_of(check), (requirement as Dictionary)["args"] as Dictionary, args, check)
		if bound == null or not AtomicEffects.check(check, _context, bound as Dictionary):
			return false
	for step: Variant in definition.get("steps", []) as Array:
		var callee := str((step as Dictionary)["call"])
		if _library.functions.has(callee) and _library.has_requirements(callee):
			var bound: Variant = _bind(_library.params_of(callee), (step as Dictionary)["args"] as Dictionary, args, callee)
			if bound == null or not requirements_met(callee, bound as Dictionary):
				return false
	return true


## Starts resolving. Returns true when resolution finished, false when it is waiting for a
## choice; answer it by appending to the context's selection, then call resume().
func run(function_name: String, args: Dictionary) -> bool:
	_stack = [_frame(function_name, args.duplicate(), "")]
	return resume()


func is_finished() -> bool:
	return _stack.is_empty()


func resume() -> bool:
	_context.choice = {}
	while not _stack.is_empty():
		var frame := _stack.back() as Dictionary
		var definition := _library.functions[frame["function"]] as Dictionary
		var steps := definition["steps"] as Array
		var index := int(frame["step"])

		if index >= steps.size():
			_stack.pop_back()
			var output := str(frame["output"])
			if not _stack.is_empty() and not output.is_empty():
				(_stack.back()["scope"] as Dictionary)[output] = _return_value(definition, frame["scope"] as Dictionary)
			continue

		frame["step"] = index + 1
		var step := steps[index] as Dictionary
		var scope := frame["scope"] as Dictionary
		if step.has("when") and not _condition_holds(step["when"] as Dictionary, scope):
			continue

		var callee := str(step["call"])
		var bound: Variant = _bind(_library.params_of(callee), step["args"] as Dictionary, scope, callee)
		if bound == null:
			continue

		if _library.functions.has(callee):
			_stack.push_back(_frame(callee, bound as Dictionary, str(step.get("as", ""))))
			continue

		var value: Variant = AtomicEffects.execute(callee, _context, bound as Dictionary)
		if value is String and value == EffectContext.PENDING:
			# Run this step again once the player has answered.
			frame["step"] = index
			return false
		_context.selection.clear()
		if step.has("as"):
			scope[str(step["as"])] = value
	return true


func _frame(function_name: String, scope: Dictionary, output: String) -> Dictionary:
	return {"function": function_name, "step": 0, "scope": scope, "output": output}


## Resolves references and checks every value against its declared type. An invalid int
## becomes 0; any other invalid value skips the step. Both are logged (7.7).
func _bind(params: Dictionary, args: Dictionary, scope: Dictionary, callee: String) -> Variant:
	var bound := {}
	for param: Variant in params:
		var type := str(params[param])
		var raw: Variant = args.get(param)
		var value: Variant = _resolve(raw, scope)
		if EffectTypes.runtime_matches(type, value):
			bound[param] = int(value) if type == EffectTypes.INT else value
			continue
		var neutral: Variant = EffectTypes.neutral(type)
		if neutral == null:
			_context.engine.log_event("[effect warning] %s: '%s' has no valid %s; step skipped" % [callee, param, type])
			return null
		_context.engine.log_event("[effect warning] %s: '%s' is not a valid %s; using %s" % [callee, param, type, neutral])
		bound[param] = neutral
	return bound


func _resolve(value: Variant, scope: Dictionary) -> Variant:
	if not EffectTypes.is_reference(value):
		return value
	var ref_name := str(value)
	if EffectTypes.CONTEXT.has(ref_name):
		return _context.value_of(ref_name)
	return scope.get(ref_name.trim_prefix("$"))


func _condition_holds(condition: Dictionary, scope: Dictionary) -> bool:
	var value: Variant = _resolve(condition.get("value"), scope)
	if not EffectTypes.runtime_matches(EffectTypes.INT, value):
		_context.engine.log_event("[effect warning] when compares a value that is not an int; step skipped")
		return false
	var left := int(value)
	for key: Variant in condition:
		if key == "value":
			continue
		var right := int(condition[key])
		match str(key):
			"eq": return left == right
			"ne": return left != right
			"gt": return left > right
			"gte": return left >= right
			"lt": return left < right
			"lte": return left <= right
	return false


func _return_value(definition: Dictionary, scope: Dictionary) -> Variant:
	var returns: Variant = definition.get("returns")
	if not returns is Dictionary:
		return null
	var type := str((returns as Dictionary)["type"])
	var value: Variant = _resolve((returns as Dictionary)["value"], scope)
	return value if EffectTypes.runtime_matches(type, value) else EffectTypes.neutral(type)
