extends SceneTree

var output := OS.get_environment("NJINGA_CAPTURE_DIR")

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    if output.is_empty():
        push_error("NJINGA_CAPTURE_DIR em falta")
        quit(1)
        return
    DirAccess.make_dir_recursive_absolute(output)
    var game = load("res://scenes/game.tscn").instantiate()
    root.add_child(game)
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_viewport().get_texture().get_image().save_png(output.path_join("menu.png"))
    game.start_level(0)
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw
    root.get_viewport().get_texture().get_image().save_png(output.path_join("nivel1.png"))
    print("[NJINGA_CAPTURE_PASS] menu and nivel1")
    quit(0)
