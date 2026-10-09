extends SceneTree

## Verifies save_progress()/load_save() round-trip across two independent
## NjingaGame instances (simulating a fresh launch after quitting). Clears
## any existing save before running, since Godot's --user-data-dir is not
## honored in --script/-s MainLoop mode:
##   godot --headless --path . -s test/save_load.gd

var _failed := false

func _initialize() -> void:
	call_deferred("_run")

func _clear_save() -> void:
	var path := OS.get_user_data_dir().path_join("njinga_save.json")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func _run() -> void:
	_clear_save()
	var first = load("res://scenes/game.tscn").instantiate()
	root.add_child(first)
	for i in range(2):
		await process_frame

	first.start_level(0)
	await process_frame
	# nivel1.json: {"type":"card", "title":"O reino do Ndongo", ..., "x":720,"y":215}
	first.player.position = Vector2(720, 215)
	first.collect_items()
	_check(first.save_data["cards"].size() == 1, "expected the first instance to record 1 card before saving")
	var saved_cards: Array = first.save_data["cards"].duplicate()
	var saved_nzimbu: int = int(first.save_data.get("nzimbu", 0))
	first.save_progress()
	first.queue_free()
	await process_frame

	var second = load("res://scenes/game.tscn").instantiate()
	root.add_child(second)
	for i in range(2):
		await process_frame

	_check(second.save_data["cards"] == saved_cards, "expected reloaded save_data.cards %s to equal saved %s" % [second.save_data["cards"], saved_cards])
	_check(int(second.save_data.get("nzimbu", 0)) == saved_nzimbu, "expected reloaded save_data.nzimbu %s to equal saved %s" % [second.save_data.get("nzimbu"), saved_nzimbu])

	if _failed:
		quit(1)
		return
	print("[SAVE_PASS] save_progress()/load_save() round-trip preserves progress")
	quit(0)

func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("[SAVE_FAIL] " + message)
		_failed = true
	return condition
