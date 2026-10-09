extends SceneTree

## Boots the real entry scene (res://scenes/game.tscn -> NjingaGame) and checks
## it reaches the menu with its content loaded. Run via:
##   godot --headless --path . -s test/smoke.gd

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: PackedScene = load("res://scenes/game.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	for i in range(4):
		await process_frame

	var failed := false
	failed = _check(game.state == "menu", "expected initial state 'menu', got '%s'" % game.state) or failed
	failed = _check(game.levels.size() == 6, "expected 6 levels loaded, got %d" % game.levels.size()) or failed
	failed = _check(game.diplomacy_data.size() == 3, "expected 3 diplomacy datasets loaded, got %d" % game.diplomacy_data.size()) or failed
	failed = _check(game.player == null, "expected no player on the menu screen, found one") or failed

	if failed:
		quit(1)
		return
	print("[SMOKE_PASS] NjingaGame booted with content loaded")
	quit(0)

func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("[SMOKE_FAIL] " + message)
		return true
	return false
