## Survives change_scene_to_file by living under SceneTree.root.
## Watches for example1 to become the current scene, then injects repro_force.
extends Node


const REPRO_FORCE := preload("res://example1/repro_force.gd")
const TARGET_SCENE := "res://example1/example1.tscn"


func _ready() -> void:
	get_tree().tree_changed.connect(_on_tree_changed)


func _on_tree_changed() -> void:
	var tree := get_tree()
	if tree == null:
		return
	var current := tree.current_scene
	if current == null:
		return
	if current.scene_file_path != TARGET_SCENE:
		return

	# Found target scene. Disconnect first so we only fire once.
	tree.tree_changed.disconnect(_on_tree_changed)

	# Wait one process frame so example1._ready (which spawns 52 cards via the
	# factory) finishes before we shift the containers.
	await tree.process_frame

	if not is_instance_valid(current):
		queue_free()
		return

	var forcer := Node.new()
	forcer.set_script(REPRO_FORCE)
	current.add_child(forcer)
	queue_free()
