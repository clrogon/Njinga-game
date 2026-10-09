extends SceneTree

## Exercises the real campaign loop on nivel1 (no diplomacy branch): start a
## level, collect an item, reach the goal, finish the level, unlock the next
## one. Clears any existing save before running, since Godot's
## --user-data-dir is not honored in --script/-s MainLoop mode:
##   godot --headless --path . -s test/gameplay_flow.gd

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

    game.start_level(0)
    await process_frame
    _check(game.state == "playing", "expected state 'playing' after start_level(0), got '%s'" % game.state)
    _check(game.player != null, "expected a player to be spawned")
    _check(game.lives == 4, "expected 4 lives on nivel1, got %d" % game.lives)

    # nivel1.json: {"type":"nzimbu","x":145,"y":205}
    game.player.position = Vector2(145, 205)
    game.collect_items()
    _check(game.nzimbu == 1, "expected 1 nzimbu collected, got %d" % game.nzimbu)
    _check(int(game.save_data.get("nzimbu", 0)) == 1, "expected save_data.nzimbu == 1, got %s" % game.save_data.get("nzimbu"))

    # nivel1.json: {"type":"card", ..., "x":720,"y":215}
    game.player.position = Vector2(720, 215)
    game.collect_items()
    _check(game.cards_found == 1, "expected 1 card collected, got %d" % game.cards_found)
    _check(game.save_data["cards"].size() == 1, "expected 1 card id recorded in save_data, got %d" % game.save_data["cards"].size())

    # nivel1.json: "goal_x": 2040, no "diplomacy" key -> should finish directly.
    game.player.position.x = float(game.level["goal_x"])
    game.update_gameplay(0.016)
    _check(game.state == "result", "expected state 'result' after reaching the goal, got '%s'" % game.state)
    _check(int(game.save_data.get("unlocked", 1)) >= 2, "expected nivel2 to be unlocked, save_data.unlocked == %s" % game.save_data.get("unlocked"))

    if _failed:
        quit(1)
        return
    print("[GAMEPLAY_PASS] start/collect/goal/finish/unlock flow works on nivel1")
    quit(0)

func _check(condition: bool, message: String) -> bool:
    if not condition:
        push_error("[GAMEPLAY_FAIL] " + message)
        _failed = true
    return condition
