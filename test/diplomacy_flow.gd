extends SceneTree

## Exercises the diplomacy minigame on nivel2 (diplomacy id "luanda1622"):
## reaching the goal must branch into diplomacy instead of finishing the
## level, and always picking each round's "best" choice must drive prestige
## up and mark the exchange done. Clears any existing save before running,
## since Godot's --user-data-dir is not honored in --script/-s MainLoop mode:
##   godot --headless --path . -s test/diplomacy_flow.gd

var _failed := false

func _initialize() -> void:
	call_deferred("_run")

func _clear_save() -> void:
	var path := OS.get_user_data_dir().path_join("njinga_save.json")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func _run() -> void:
	_clear_save()
	var game = load("res://scenes/game.tscn").instantiate()
	root.add_child(game)
	for i in range(2):
		await process_frame

	# nivel2 is unlocked by default (save_data.unlocked starts at 1 -> level
	# index 0 only); force it open so start_level(1) is allowed.
	game.save_data["unlocked"] = 2
	game.start_level(1)
	await process_frame
	_check(game.level.get("diplomacy", "") == "luanda1622", "expected nivel2 to reference diplomacy 'luanda1622', got '%s'" % game.level.get("diplomacy"))

	# nivel2.json: "goal_x": 2130 -> reaching it with an unresolved diplomacy
	# branch must open the exchange instead of finishing the level.
	game.player.position.x = float(game.level["goal_x"])
	game.update_gameplay(0.016)
	_check(game.state == "diplomacy", "expected state 'diplomacy' after reaching the goal on a diplomacy level, got '%s'" % game.state)

	var rounds: Array = game.dialogue.get("rounds", [])
	_check(rounds.size() > 0, "expected at least one diplomacy round loaded")
	var prestige_before := int(game.prestige)
	for round_data in rounds:
		game.choose_diplomacy(str(round_data.get("best", "")))

	_check(game.diplomacy_done, "expected diplomacy_done to be true after answering every round")
	_check(game.round_index == rounds.size(), "expected round_index to reach %d, got %d" % [rounds.size(), game.round_index])
	_check(int(game.prestige) > prestige_before, "expected prestige to rise when always picking the best answer (started at %d, ended at %d)" % [prestige_before, game.prestige])

	if _failed:
		quit(1)
		return
	print("[DIPLOMACY_PASS] goal branches into diplomacy and best answers raise prestige")
	quit(0)

func _check(condition: bool, message: String) -> bool:
	if not condition:
		push_error("[DIPLOMACY_FAIL] " + message)
		_failed = true
	return condition
