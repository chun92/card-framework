## Repro for issue #38 (card return-to-original offset).
## Boot this scene as the project's main scene, then press Start.
## After example1 loads, draw a card to hand, drag it outside any drop zone,
## and observe whether it returns to its original slot or to an offset position.
extends Control


const REPRO_FORCE_INSTALLER := preload("res://example1/repro_force_installer.gd")


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://example1/example1.tscn")


func _on_start_deferred_pressed() -> void:
	# Same change but after waiting one process frame, to compare timing.
	await get_tree().process_frame
	get_tree().change_scene_to_file("res://example1/example1.tscn")


func _on_start_forced_pressed() -> void:
	# Attach a helper node to SceneTree.root BEFORE the scene change so it
	# survives. The helper waits for example1 to become current, then injects
	# repro_force — simulating the deferred-layout drift to force the bug.
	var tree := get_tree()
	var installer := Node.new()
	installer.set_script(REPRO_FORCE_INSTALLER)
	tree.root.add_child(installer)
	tree.change_scene_to_file("res://example1/example1.tscn")
