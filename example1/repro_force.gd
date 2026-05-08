## Forced repro for issue #38.
## Attach this to the Example1 root (or instantiate after change_scene).
## It nudges every CardContainer's global_position one frame after _ready,
## simulating the deferred-layout shift that scene-change exposes.
##
## Expected: cards remain visually correct, but original_destination still
## points at the pre-shift coordinates → return_to_original lands offset.
extends Node


@export var shift: Vector2 = Vector2(120, 80)


func _ready() -> void:
	# Wait for normal example1 setup (factory creates 52 cards in its _ready).
	await get_tree().process_frame
	var moved: int = 0
	_walk(get_tree().current_scene, func(node):
		if node is CardContainer:
			node.global_position += shift
			moved += 1
	)
	print("[repro_force] shifted %d CardContainer(s) by %s" % [moved, shift])


func _walk(node: Node, fn: Callable) -> void:
	fn.call(node)
	for c in node.get_children():
		_walk(c, fn)
