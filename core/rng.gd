class_name Rng
extends RefCounted

var seed_value: int = 0
var _generator := RandomNumberGenerator.new()


func _init(game_seed: int) -> void:
	seed_value = game_seed
	_generator.seed = game_seed


func shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := _generator.randi_range(0, i)
		var temp: Variant = items[i]
		items[i] = items[j]
		items[j] = temp


func coin_flip() -> bool:
	return _generator.randi_range(0, 1) == 1
