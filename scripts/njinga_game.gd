extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/njinga_player.gd")
const LEVEL_PATHS = [
    "res://data/levels/nivel1.json",
    "res://data/levels/nivel2.json",
    "res://data/levels/nivel3.json",
    "res://data/levels/nivel4.json",
    "res://data/levels/nivel5.json",
    "res://data/levels/nivel6.json"
]
const DIPLOMACY_PATHS = {
    "luanda1622": "res://data/diplomacy/luanda1622.json",
    "holandeses1641": "res://data/diplomacy/holandeses1641.json",
    "tratado1656": "res://data/diplomacy/tratado1656.json"
}
const SAVE_FILE := "user://njinga_save.json"
const VIEW_SIZE := Vector2(480, 270)

var levels: Array = []
var diplomacy_data: Dictionary = {}
var current_level := 0
var level: Dictionary = {}
var player: CharacterBody2D
var camera: Camera2D
var platforms: Array = []
var collectibles: Array = []
var enemies: Array = []
var hazards: Array = []
var projectiles: Array = []
var stage_nodes: Array[Node] = []
var checkpoint := Vector2(28, 210)
var goal_triggered := false
var state := "menu"
var message := ""
var message_time := 0.0
var save_data := {"unlocked": 1, "cards": [], "nzimbu": 0, "infinite_lives": false, "text_scale": 1.0, "levels": {}, "key_bindings": {"left": KEY_A, "right": KEY_D, "jump": KEY_SPACE, "attack": KEY_J, "bow": KEY_K, "interact": KEY_E}}
var key_bindings: Dictionary = {"left": KEY_A, "right": KEY_D, "jump": KEY_SPACE, "attack": KEY_J, "bow": KEY_K, "interact": KEY_E}
var lives := 3
var nzimbu := 0
var cards_found := 0
var captives_freed := 0
var allies_found := 0
var materials_found := 0
var arrows := 0
var prestige := 50
var pursuit_timer := 0.0
var hiding := false
var round_index := 0
var dialogue: Dictionary = {}
var diplomacy_done := false
var result_text := ""
var was_interact := false
var touch_left := false
var touch_right := false
var touch_jump := false
var touch_attack := false
var touch_bow := false
var touch_interact := false

var ui_layer: CanvasLayer
var screen_root: Control
var hud_root: Control
var touch_root: Control
var title_label: Label
var hud_label: Label
var objective_label: Label
var toast_label: Label

var ink := Color("#271b2a")
var cream := Color("#f6e6bd")
var gold := Color("#e0aa4f")
var green := Color("#25756a")
var clay := Color("#bf6846")
var blue := Color("#2f6c85")

func _ready() -> void:
    load_content()
    load_save()
    ui_layer = CanvasLayer.new()
    ui_layer.layer = 20
    add_child(ui_layer)
    screen_root = Control.new()
    screen_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    screen_root.mouse_filter = Control.MOUSE_FILTER_PASS
    ui_layer.add_child(screen_root)
    hud_root = Control.new()
    hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud_root.visible = false
    ui_layer.add_child(hud_root)
    touch_root = Control.new()
    touch_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    touch_root.mouse_filter = Control.MOUSE_FILTER_PASS
    touch_root.visible = false
    ui_layer.add_child(touch_root)
    show_menu()
    queue_redraw()

func load_content() -> void:
    for path in LEVEL_PATHS:
        var data = read_json(path)
        if data is Dictionary:
            levels.append(data)
    for key in DIPLOMACY_PATHS:
        var data = read_json(DIPLOMACY_PATHS[key])
        if data is Dictionary:
            diplomacy_data[key] = data

func read_json(path: String):
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    return JSON.parse_string(file.get_as_text())

func load_save() -> void:
    var loaded = {}
    if OS.has_feature("web"):
        var browser_save = JavaScriptBridge.eval("localStorage.getItem('njinga_save') || '';")
        if browser_save is String and not browser_save.is_empty():
            loaded = JSON.parse_string(browser_save)
    if FileAccess.file_exists(SAVE_FILE):
        var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
        if file != null and loaded.is_empty():
            loaded = JSON.parse_string(file.get_as_text())
    if loaded is Dictionary:
        for key in loaded:
            save_data[key] = loaded[key]
    if not save_data.has("levels"):
        save_data["levels"] = {}
    if not save_data.has("key_bindings"):
        save_data["key_bindings"] = key_bindings.duplicate()
    for action in key_bindings:
        key_bindings[action] = int(save_data["key_bindings"].get(action, key_bindings[action]))

func save_progress() -> void:
    var encoded := JSON.stringify(save_data)
    var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if file != null:
        file.store_string(encoded)
    if OS.has_feature("web"):
        JavaScriptBridge.eval("localStorage.setItem('njinga_save', " + JSON.stringify(encoded) + ");")

func key_down(action: String, fallback: int) -> bool:
    return Input.is_key_pressed(int(key_bindings.get(action, fallback)))

func key_label(code: int) -> String:
    match code:
        KEY_SPACE: return "Espaço"
        KEY_A: return "A"
        KEY_D: return "D"
        KEY_E: return "E"
        KEY_F: return "F"
        KEY_J: return "J"
        KEY_K: return "K"
        KEY_L: return "L"
        KEY_W: return "W"
        KEY_LEFT: return "←"
        KEY_RIGHT: return "→"
        KEY_UP: return "↑"
        _: return "Tecla " + str(code)

func add_key_setting(box: VBoxContainer, title: String, action: String, options: Array) -> void:
    var current: int = int(key_bindings.get(action, options[0]))
    var button := make_button(title + ": " + key_label(current), 11)
    button.pressed.connect(func():
        var index: int = options.find(current) + 1
        if index >= options.size():
            index = 0
        key_bindings[action] = int(options[index])
        save_data["key_bindings"] = key_bindings.duplicate()
        save_progress()
        show_settings()
    )
    box.add_child(button)

func _process(delta: float) -> void:
    if message_time > 0.0:
        message_time -= delta
        if message_time <= 0.0 and toast_label != null:
            toast_label.visible = false
    if state == "playing":
        update_gameplay(delta)
    queue_redraw()

func update_gameplay(delta: float) -> void:
    if player == null:
        return
    var interact_now := key_down("interact", KEY_E) or touch_interact
    if interact_now and not was_interact:
        interact_nearby()
    was_interact = interact_now
    pursuit_timer = maxf(0.0, pursuit_timer - delta)
    update_enemies(delta)
    update_projectiles(delta)
    collect_items()
    check_hazards()
    check_checkpoints()
    check_stealth()
    if player.position.x >= float(level.get("goal_x", 2000)) and not goal_triggered:
        goal_triggered = true
        if level.has("diplomacy") and not diplomacy_done:
            begin_diplomacy()
        else:
            finish_level()
    update_hud()

func update_enemies(delta: float) -> void:
    for i in range(enemies.size()):
        if not bool(enemies[i].get("alive", true)):
            continue
        if enemies[i].get("type", "") in ["patrulha", "sentinela", "saqueador", "guarda", "mosqueteiro"]:
            var direction := float(enemies[i].get("dir", 1.0))
            enemies[i]["x"] = float(enemies[i]["x"]) + direction * delta * (18.0 if enemies[i].get("type", "") == "patrulha" else 10.0)
            var origin := float(enemies[i].get("origin", enemies[i]["x"]))
            if absf(float(enemies[i]["x"]) - origin) > 42.0:
                enemies[i]["dir"] = -direction
        if enemies[i].get("type", "") == "campeao" and absf(player.position.x - float(enemies[i]["x"])) < 70.0:
            enemies[i]["dir"] = -1.0 if player.position.x < float(enemies[i]["x"]) else 1.0
        if enemies[i].get("type", "") == "canhao" and fmod(Time.get_ticks_msec() / 1000.0 + i, 3.0) < 0.025:
            show_toast("A bateria dispara — observa o arco da bala.")

func update_projectiles(delta: float) -> void:
    for i in range(projectiles.size() - 1, -1, -1):
        projectiles[i]["x"] = float(projectiles[i]["x"]) + float(projectiles[i]["dir"]) * 170.0 * delta
        projectiles[i]["life"] = float(projectiles[i]["life"]) - delta
        var removed := false
        for j in range(enemies.size()):
            if not bool(enemies[j].get("alive", true)):
                continue
            if Vector2(float(enemies[j]["x"]), float(enemies[j]["y"]) - 10).distance_to(Vector2(float(projectiles[i]["x"]), float(projectiles[i]["y"]))) < 15.0:
                enemies[j]["alive"] = false
                show_toast("Impacto certeiro — o adversário foge.")
                removed = true
                break
        if removed or float(projectiles[i]["life"]) <= 0.0:
            projectiles.remove_at(i)

func collect_items() -> void:
    var p := player.position
    for i in range(collectibles.size()):
        if bool(collectibles[i].get("taken", false)):
            continue
        var item_pos := Vector2(float(collectibles[i]["x"]), float(collectibles[i]["y"]))
        if p.distance_to(item_pos) > 18.0:
            continue
        var kind := str(collectibles[i].get("type", ""))
        if kind == "card":
            collectibles[i]["taken"] = true
            cards_found += 1
            var card_id: String = str(level["id"]) + ":" + str(i)
            if card_id not in save_data["cards"]:
                save_data["cards"].append(card_id)
            save_progress()
            show_toast("Cartão desbloqueado: " + str(collectibles[i].get("title", "")))
        elif kind == "nzimbu":
            collectibles[i]["taken"] = true
            nzimbu += 1
            save_data["nzimbu"] = int(save_data.get("nzimbu", 0)) + 1
        elif kind == "captive":
            collectibles[i]["taken"] = true
            captives_freed += 1
            show_toast("Cativo libertado. A cancela abre-se sem violência.")
        elif kind == "ally":
            collectibles[i]["taken"] = true
            allies_found += 1
            show_toast("Aliado reunido: " + str(allies_found) + "/5")
        elif kind == "material":
            collectibles[i]["taken"] = true
            materials_found += 1
            show_toast("Material recolhido para reconstruir a cidade.")
        elif kind == "quiver":
            collectibles[i]["taken"] = true
            arrows = min(10, arrows + 5)
            show_toast("Aljava encontrada: +5 flechas.")
    save_progress()

func check_hazards() -> void:
    var player_rect := Rect2(player.position + Vector2(-6, -22), Vector2(12, 22))
    for hazard in hazards:
        var rect := Rect2(float(hazard["x"]), float(hazard["y"]), float(hazard["w"]), float(hazard["h"]))
        if player_rect.intersects(rect):
            hurt_player("Cuidado: " + str(hazard.get("type", "perigo")) + ".")

func check_checkpoints() -> void:
    for point in level.get("checkpoints", []):
        var x := float(point[0]) if point is Array else float(point.get("x", 0))
        if absf(player.position.x - x) < 16.0 and checkpoint.x != x:
            checkpoint = Vector2(x, 210)
            show_toast("Ngoma tocado — ponto guardado.")
            lives = min(4, lives + 1)

func check_stealth() -> void:
    hiding = current_level == 2 and player.position.x > 980.0 and player.position.x < 1110.0
    if hiding:
        pursuit_timer = 0.0
    for enemy in enemies:
        if not bool(enemy.get("alive", true)) or enemy.get("type", "") != "patrulha":
            continue
        var vision := float(enemy.get("vision", 90.0))
        var distance := player.position.x - float(enemy["x"])
        var dir := float(enemy.get("dir", 1.0))
        if not hiding and signf(distance) == dir and absf(distance) < vision and absf(player.position.y - float(enemy["y"])) < 35.0:
            pursuit_timer = 5.0
            show_toast("Foste vista! Tens 5 segundos para escapar ou esconder-te.")

func interact_nearby() -> void:
    for item in collectibles:
        if bool(item.get("taken", false)):
            continue
        if item.get("type", "") == "captive" and player.position.distance_to(Vector2(float(item["x"]), float(item["y"]))) < 28.0:
            item["taken"] = true
            captives_freed += 1
            show_toast("Cativo libertado.")
            return
    show_toast("Não há nada para interagir aqui.")

func hurt_player(text: String) -> void:
    if player == null or player.invulnerable > 0.0:
        return
    player.hurt()
    lives -= 1
    if bool(save_data.get("infinite_lives", false)):
        lives = max(1, lives)
    show_toast(text)
    if lives <= 0:
        show_result("A tentativa terminou", "A coragem também aprende com uma pausa. Recomeça do último Ngoma ou activa Vidas infinitas na Acessibilidade.", true)
    else:
        player.respawn(checkpoint)

func on_player_fell() -> void:
    hurt_player("A escarpa ficou para trás — regressas ao último Ngoma.")
    if player != null:
        player.respawn(checkpoint)

func on_attack() -> void:
    if state != "playing" or player == null:
        return
    var reach := 28.0
    for enemy in enemies:
        if not bool(enemy.get("alive", true)):
            continue
        var distance := float(enemy["x"]) - player.position.x
        if absf(distance) < reach and signf(distance) == player.facing:
            enemy["alive"] = false
            show_toast("Desmaiou e fugiu — sem sangue, sem mortes em cena.")
            return
    show_toast("O machado abre caminho.")

func on_bow() -> void:
    if state != "playing" or not player.bow_unlocked:
        return
    if arrows <= 0:
        show_toast("Sem flechas. Procura uma aljava.")
        return
    arrows -= 1
    projectiles.append({"x": player.position.x + player.facing * 10.0, "y": player.position.y - 13.0, "dir": player.facing, "life": 2.5})

func build_world() -> void:
    clear_stage_nodes()
    platforms.clear()
    collectibles.clear()
    enemies.clear()
    hazards.clear()
    projectiles.clear()
    level = levels[current_level]
    checkpoint = Vector2(float(level["spawn"][0]), float(level["spawn"][1]))
    goal_triggered = false
    diplomacy_done = false
    cards_found = 0
    captives_freed = 0
    allies_found = 0
    materials_found = 0
    arrows = 10 if current_level >= 3 else 0
    prestige = 50
    pursuit_timer = 0.0
    for p in level.get("platforms", []):
        platforms.append(p)
        var body := StaticBody2D.new()
        body.position = Vector2(float(p[0]) + float(p[2]) / 2.0, float(p[1]) + float(p[3]) / 2.0)
        body.collision_layer = 1
        var shape := CollisionShape2D.new()
        var rect := RectangleShape2D.new()
        rect.size = Vector2(float(p[2]), float(p[3]))
        shape.shape = rect
        body.add_child(shape)
        add_child(body)
        stage_nodes.append(body)
    for raw in level.get("collectibles", []):
        var item: Dictionary = raw.duplicate(true)
        item["taken"] = false
        collectibles.append(item)
    for raw_enemy in level.get("enemies", []):
        var enemy: Dictionary = raw_enemy.duplicate(true)
        enemy["alive"] = true
        enemy["dir"] = 1.0
        enemy["origin"] = float(enemy.get("x", 0))
        enemies.append(enemy)
    for raw_hazard in level.get("hazards", []):
        hazards.append(raw_hazard.duplicate(true))
    player = PLAYER_SCRIPT.new()
    player.position = checkpoint
    player.setup(current_level, current_level >= 2, current_level >= 3)
    player.attack_requested.connect(on_attack)
    player.bow_requested.connect(on_bow)
    player.fell.connect(on_player_fell)
    add_child(player)
    stage_nodes.append(player)
    camera = Camera2D.new()
    camera.position = Vector2(0, -32)
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 6.0
    camera.limit_left = 0
    camera.limit_right = int(level.get("world_width", 2200))
    camera.limit_top = 0
    camera.limit_bottom = 270
    player.add_child(camera)
    lives = 4 if current_level == 0 else 3
    state = "playing"
    hud_root.visible = true
    touch_root.visible = true
    clear_screen()
    build_hud()
    show_toast(str(level.get("objective", "Avança.")))

func clear_stage_nodes() -> void:
    for node in stage_nodes:
        if is_instance_valid(node):
            node.queue_free()
    stage_nodes.clear()
    player = null

func start_level(index: int) -> void:
    if index < 0 or index >= levels.size():
        return
    if index + 1 > int(save_data.get("unlocked", 1)):
        show_toast("Este nível ainda está fechado. Completa a fase anterior.")
        return
    current_level = index
    build_world()

func finish_level() -> void:
    if state != "playing":
        return
    state = "result"
    hud_root.visible = false
    touch_root.visible = false
    clear_stage_nodes()
    var next_unlocked: int = int(mini(levels.size(), current_level + 2))
    save_data["unlocked"] = max(int(save_data.get("unlocked", 1)), next_unlocked)
    save_data["levels"][str(current_level + 1)] = {"cards": cards_found, "nzimbu": nzimbu, "captives": captives_freed, "prestige": prestige}
    save_progress()
    var suffix := ""
    if current_level == 3:
        suffix = " Aliados reunidos: " + str(allies_found) + "/5."
    elif current_level == 5:
        suffix = " Materiais recolhidos: " + str(materials_found) + "."
    result_text = str(level.get("finale", "A fase termina.")) + suffix
    if current_level == levels.size() - 1:
        result_text += "\n\nA Crónica fecha este arco com o reencontro de Kambu e o legado de Njinga em Angola."
    show_result(level["title"], result_text, false)

func begin_diplomacy() -> void:
    state = "diplomacy"
    dialogue = diplomacy_data.get(str(level.get("diplomacy", "")), {})
    round_index = 0
    prestige = 62 if current_level == 1 else 50
    hud_root.visible = false
    touch_root.visible = false
    show_diplomacy()

func choose_diplomacy(choice: String) -> void:
    if state != "diplomacy":
        return
    var rounds: Array = dialogue.get("rounds", [])
    if round_index >= rounds.size():
        return
    var best := str(rounds[round_index].get("best", "Astuta"))
    if choice == best:
        prestige = min(100, prestige + 15)
    elif (choice == "Conciliadora" and best == "Astuta") or (choice == "Astuta" and best == "Conciliadora"):
        prestige = min(100, prestige + 6)
    else:
        prestige = max(0, prestige - 10)
    round_index += 1
    if round_index >= rounds.size():
        diplomacy_done = true
        show_diplomacy_result()
    else:
        show_diplomacy()

func show_diplomacy_result() -> void:
    clear_screen()
    var panel := make_panel(Vector2(36, 30), Vector2(408, 210), Color("#173d45"))
    screen_root.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    add_label(box, str(dialogue.get("title", "Diplomacia")), 19, gold)
    var tier := "Resultado histórico completo" if prestige > 70 else ("Resultado parcial" if prestige >= 40 else "A conversa precisa de outra tentativa")
    add_label(box, "Prestígio: " + str(prestige) + "/100 — " + tier, 14, cream)
    add_label(box, "As respostas podem mudar o tom, mas a diplomacia nunca bloqueia a viagem.", 12, Color("#c9ded0"), true)
    var b := make_button("Continuar", 14)
    b.pressed.connect(func():
        state = "playing"
        diplomacy_done = true
        finish_level()
    )
    box.add_child(b)

func show_diplomacy() -> void:
    clear_screen()
    var panel := make_panel(Vector2(22, 18), Vector2(436, 234), Color("#183f49"))
    screen_root.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 5)
    panel.add_child(box)
    add_label(box, str(dialogue.get("title", "Diplomacia")), 17, gold)
    add_label(box, str(dialogue.get("interlocutor", "Interlocutor")) + " · Ronda " + str(round_index + 1) + "/" + str(dialogue.get("rounds", []).size()), 11, Color("#b8d8c8"))
    var rounds: Array = dialogue.get("rounds", [])
    var current: Dictionary = rounds[round_index]
    add_label(box, str(current.get("request", "Escolhe uma resposta.")), 15, cream, true)
    add_label(box, "Pista: " + str(current.get("hint", "Lê com atenção.")), 11, Color("#c7d9c2"), true)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)
    box.add_child(row)
    for choice in ["Firme", "Conciliadora", "Astuta"]:
        var b := make_button(choice, 12)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(func(): choose_diplomacy(choice))
        row.add_child(b)
    add_label(box, "Prestígio actual: " + str(prestige) + "/100", 12, gold)

func show_result(title: String, body: String, failed: bool) -> void:
    state = "result"
    clear_screen()
    var panel := make_panel(Vector2(28, 28), Vector2(424, 214), Color("#3d2730"))
    screen_root.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 7)
    panel.add_child(box)
    add_label(box, title, 19, gold)
    add_label(box, body, 13, cream, true)
    if not failed:
        add_label(box, "Cartões nesta fase: " + str(cards_found) + " · Nzimbu: " + str(nzimbu), 12, Color("#c9ded0"))
    var primary := make_button("Recomeçar fase" if failed else ("Próximo nível" if current_level < levels.size() - 1 else "Ver final"), 13)
    primary.pressed.connect(func():
        if failed:
            start_level(current_level)
        elif current_level < levels.size() - 1:
            start_level(current_level + 1)
        else:
            show_chronicle()
    )
    box.add_child(primary)
    var back := make_button("Voltar ao menu", 12)
    back.pressed.connect(show_menu)
    box.add_child(back)

func build_hud() -> void:
    for child in hud_root.get_children():
        child.queue_free()
    var panel := PanelContainer.new()
    panel.position = Vector2(8, 7)
    panel.size = Vector2(464, 31)
    panel.add_theme_stylebox_override("panel", panel_style(Color(0.12, 0.11, 0.15, 0.88), Color("#d6a354")))
    hud_root.add_child(panel)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    panel.add_child(row)
    hud_label = add_label(row, "", 11, cream)
    hud_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    objective_label = add_label(row, "", 10, Color("#c4decf"))
    objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    toast_label = add_label(hud_root, "", 11, cream, true)
    toast_label.position = Vector2(16, 218)
    toast_label.size = Vector2(448, 30)
    toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast_label.visible = false
    update_hud()

func update_hud() -> void:
    if hud_label == null or level.is_empty():
        return
    var weapon := ""
    if current_level >= 3:
        weapon = " · Flechas " + str(arrows)
    elif current_level >= 2:
        weapon = " · Machado"
    hud_label.text = "N" + str(current_level + 1) + "  " + str(level.get("title", "")) + "   ♥ " + str(lives) + "   ◈ " + str(nzimbu) + weapon
    var objective := str(level.get("objective", "Avança."))
    if current_level == 3:
        objective += "  Aliados " + str(allies_found) + "/5"
    elif current_level == 5:
        objective += "  Materiais " + str(materials_found) + "/4"
    if current_level == 2 and hiding:
        objective = "Escondida no capim alto · " + objective
    if pursuit_timer > 0.0:
        objective = "PERSEGUIÇÃO " + str(snapped(pursuit_timer, 0.1)) + "s · " + objective
    objective_label.text = objective

func show_toast(text: String) -> void:
    message = text
    message_time = 3.0
    if toast_label != null:
        toast_label.text = text
        toast_label.visible = true

func show_menu() -> void:
    state = "menu"
    hud_root.visible = false
    touch_root.visible = false
    clear_stage_nodes()
    clear_screen()
    var panel := make_panel(Vector2(34, 17), Vector2(412, 236), Color("#202638"))
    screen_root.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 5)
    panel.add_child(box)
    var brand := add_label(box, "NJINGA", 31, gold)
    brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    add_label(box, "Rainha do Ndongo e da Matamba", 13, Color("#b9dcc1"), false, HORIZONTAL_ALIGNMENT_CENTER)
    add_label(box, "Uma aventura histórica em seis momentos", 11, cream, false, HORIZONTAL_ALIGNMENT_CENTER)
    var start := make_button("Começar campanha", 14)
    start.pressed.connect(func(): start_level(min(int(save_data.get("unlocked", 1)) - 1, 5)))
    box.add_child(start)
    var choose := make_button("Escolher nível", 12)
    choose.pressed.connect(show_level_select)
    box.add_child(choose)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 5)
    box.add_child(row)
    for item in [["Crónica", Callable(self, "show_chronicle")], ["Pais e professores", Callable(self, "show_parents")]]:
        var b := make_button(item[0], 11)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(item[1])
        row.add_child(b)
    var row2 := HBoxContainer.new()
    row2.add_theme_constant_override("separation", 5)
    box.add_child(row2)
    for item in [["Acessibilidade", Callable(self, "show_settings")], ["Créditos", Callable(self, "show_credits")]]:
        var b := make_button(item[0], 11)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(item[1])
        row2.add_child(b)
    add_label(box, "Mover A/D ou setas · Espaço saltar · J machado · K arco · E interagir", 9, Color("#9eb7ad"), false, HORIZONTAL_ALIGNMENT_CENTER)

func show_level_select() -> void:
    clear_screen()
    var panel := make_panel(Vector2(25, 16), Vector2(430, 238), Color("#202638"))
    screen_root.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 4)
    panel.add_child(box)
    add_label(box, "Escolher nível", 20, gold)
    add_label(box, "Completa uma fase para abrir a seguinte.", 11, cream, true)
    for i in range(levels.size()):
        var button_text := "N" + str(i + 1) + "  " + str(levels[i].get("title", "")) + " · " + str(levels[i].get("era", ""))
        if i + 1 > int(save_data.get("unlocked", 1)):
            button_text += "  [fechado]"
        var b := make_button(button_text, 11)
        b.disabled = i + 1 > int(save_data.get("unlocked", 1))
        b.pressed.connect(func(): start_level(i))
        box.add_child(b)
    var back := make_button("Voltar", 11)
    back.pressed.connect(show_menu)
    box.add_child(back)

func show_chronicle() -> void:
    state = "chronicle"
    clear_screen()
    var panel := make_panel(Vector2(20, 12), Vector2(440, 246), Color("#202638"))
    screen_root.add_child(panel)
    var scroll := ScrollContainer.new()
    scroll.size = Vector2(414, 214)
    scroll.position = Vector2(10, 10)
    panel.add_child(scroll)
    var box := VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 6)
    scroll.add_child(box)
    add_label(box, "A CRÓNICA", 21, gold)
    add_label(box, "Cartões encontrados: " + str(save_data.get("cards", []).size()), 11, Color("#b9dcc1"), true)
    for i in range(levels.size()):
        add_label(box, "N" + str(i + 1) + " · " + str(levels[i].get("title", "")) + " · " + str(levels[i].get("era", "")), 13, cream)
        for item in levels[i].get("collectibles", []):
            if item.get("type", "") != "card":
                continue
            var card_id: String = str(levels[i]["id"]) + ":" + str(levels[i].get("collectibles", []).find(item))
            var unlocked: bool = card_id in save_data.get("cards", [])
            var text := ("▰ " + str(item.get("title", "")) + " [" + str(item.get("certainty", "")) + "]\n" + str(item.get("text", ""))) if unlocked else "▱ Cartão ainda por encontrar"
            add_label(box, text, 10, Color("#d5cda9") if unlocked else Color("#777b86"), true)
    var back := make_button("Voltar ao menu", 11)
    back.pressed.connect(show_menu)
    box.add_child(back)

func show_parents() -> void:
    clear_screen()
    var panel := make_panel(Vector2(25, 24), Vector2(430, 222), Color("#243e45"))
    screen_root.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    add_label(box, "PARA PAIS E PROFESSORES", 18, gold)
    add_label(box, "Nota de honestidade histórica", 12, Color("#b9dcc1"))
    add_label(box, "Este jogo simplifica uma história complexa para fins educativos. Njinga Mbandi foi uma líder política e militar, mas também participou no comércio de escravos da época. A violência familiar, a morte do filho e os rituais imbangala ficam fora do jogo.\n\nOs cartões distinguem factos documentados (D), relatos discutidos (R) e liberdade criativa (F). Consulte as fontes nos Créditos e peça revisão a um historiador ou docente angolano antes de usar o jogo em contexto escolar.", 11, cream, true)
    var back := make_button("Voltar", 11)
    back.pressed.connect(show_menu)
    box.add_child(back)

func show_settings() -> void:
    clear_screen()
    var panel := make_panel(Vector2(20, 8), Vector2(440, 254), Color("#202638"))
    screen_root.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 4)
    panel.add_child(box)
    add_label(box, "ACESSIBILIDADE", 20, gold)
    add_label(box, "Vidas infinitas torna a viagem mais acessível; o tamanho do texto pode ser aumentado. As opções ficam guardadas neste navegador.", 11, cream, true)
    var lives_button := make_button("Vidas infinitas: " + ("ON" if bool(save_data.get("infinite_lives", false)) else "OFF"), 12)
    lives_button.pressed.connect(func():
        save_data["infinite_lives"] = not bool(save_data.get("infinite_lives", false))
        save_progress()
        show_settings()
    )
    box.add_child(lives_button)
    var text_button := make_button("Tamanho do texto: " + str(save_data.get("text_scale", 1.0)) + "x", 12)
    text_button.pressed.connect(func():
        var value := float(save_data.get("text_scale", 1.0))
        save_data["text_scale"] = 1.25 if value < 1.25 else (1.5 if value < 1.5 else 1.0)
        save_progress()
        show_settings()
    )
    box.add_child(text_button)
    add_key_setting(box, "Mover para a esquerda", "left", [KEY_A, KEY_LEFT])
    add_key_setting(box, "Mover para a direita", "right", [KEY_D, KEY_RIGHT])
    add_key_setting(box, "Saltar", "jump", [KEY_SPACE, KEY_W, KEY_UP])
    add_key_setting(box, "Interagir", "interact", [KEY_E, KEY_F])
    var back := make_button("Voltar", 11)
    back.pressed.connect(show_menu)
    box.add_child(back)

func show_credits() -> void:
    clear_screen()
    var panel := make_panel(Vector2(24, 20), Vector2(432, 230), Color("#202638"))
    screen_root.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 6)
    panel.add_child(box)
    add_label(box, "CRÉDITOS", 20, gold)
    add_label(box, "Njinga: Rainha do Ndongo e da Matamba\nMVP educativo · arte procedural original · Godot 4", 13, cream, true)
    add_label(box, "História: proposta de jogo, versão 1.0, com referências UNESCO Women in African History; South African History Online; Wikipedia; Linda M. Heywood, Njinga of Angola.\n\nA arte do MVP é desenhada em código. Os nomes e acontecimentos seguem a proposta; graus D/R/F aparecem na Crónica.", 10, Color("#c9ded0"), true)
    var back := make_button("Voltar", 11)
    back.pressed.connect(show_menu)
    box.add_child(back)

func setup_touch_controls() -> void:
    for child in touch_root.get_children():
        child.queue_free()
    add_touch_button("◀", Vector2(16, 224), "left")
    add_touch_button("▶", Vector2(58, 224), "right")
    add_touch_button("SALTA", Vector2(350, 224), "jump")
    add_touch_button("J", Vector2(300, 224), "attack")
    add_touch_button("K", Vector2(264, 224), "bow")
    add_touch_button("E", Vector2(104, 224), "interact")

func add_touch_button(text: String, pos: Vector2, action: String) -> void:
    var button := Button.new()
    button.text = text
    button.position = pos
    button.size = Vector2(38 if text != "SALTA" else 66, 28)
    button.add_theme_font_size_override("font_size", 10)
    button.add_theme_stylebox_override("normal", panel_style(Color(0.08, 0.12, 0.16, 0.86), Color("#d6a354")))
    button.button_down.connect(func(): set_touch(action, true))
    button.button_up.connect(func(): set_touch(action, false))
    touch_root.add_child(button)

func set_touch(action: String, value: bool) -> void:
    if action == "left": touch_left = value
    elif action == "right": touch_right = value
    elif action == "jump": touch_jump = value
    elif action == "attack": touch_attack = value
    elif action == "bow": touch_bow = value
    elif action == "interact": touch_interact = value

func clear_screen() -> void:
    for child in screen_root.get_children():
        child.queue_free()
    if state == "playing":
        setup_touch_controls()
    else:
        for child in touch_root.get_children():
            child.queue_free()

func make_panel(pos: Vector2, size: Vector2, color: Color) -> PanelContainer:
    var panel := PanelContainer.new()
    panel.position = pos
    panel.size = size
    panel.add_theme_stylebox_override("panel", panel_style(color, Color("#d6a354")))
    return panel

func panel_style(bg: Color, border: Color = Color("#b27b46")) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg
    style.border_color = border
    style.set_border_width_all(2)
    style.set_corner_radius_all(5)
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style

func make_button(text: String, size: int) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size = Vector2(0, 23)
    button.add_theme_font_size_override("font_size", int(float(size) * float(save_data.get("text_scale", 1.0))))
    button.add_theme_color_override("font_color", cream)
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", panel_style(Color("#34495b"), Color("#668e83")))
    button.add_theme_stylebox_override("hover", panel_style(Color("#4a6d69"), gold))
    button.add_theme_stylebox_override("pressed", panel_style(Color("#6d4b46"), gold))
    button.add_theme_stylebox_override("disabled", panel_style(Color("#30343e"), Color("#555b66")))
    return button

func add_label(parent: Node, text: String, size: int, color: Color, wrap := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", int(float(size) * float(save_data.get("text_scale", 1.0))))
    label.add_theme_color_override("font_color", color)
    label.horizontal_alignment = align
    if wrap:
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    parent.add_child(label)
    return label

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        if state == "playing":
            show_pause()
        elif state != "menu":
            show_menu()

func show_pause() -> void:
    state = "pause"
    hud_root.visible = false
    touch_root.visible = false
    clear_screen()
    var panel := make_panel(Vector2(92, 42), Vector2(296, 175), Color("#202638"))
    screen_root.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 7)
    panel.add_child(box)
    add_label(box, "PAUSA", 22, gold)
    add_label(box, str(level.get("title", "")) + "\n" + str(level.get("place", "")), 12, cream, true)
    var resume := make_button("Continuar", 12)
    resume.pressed.connect(func():
        state = "playing"
        hud_root.visible = true
        touch_root.visible = true
        clear_screen()
        build_hud()
    )
    box.add_child(resume)
    var restart := make_button("Recomeçar fase", 12)
    restart.pressed.connect(func(): start_level(current_level))
    box.add_child(restart)
    var menu := make_button("Voltar ao menu", 12)
    menu.pressed.connect(show_menu)
    box.add_child(menu)

func _draw() -> void:
    var world_width := float(level.get("world_width", 2600)) if not level.is_empty() else 480.0
    var theme := str(level.get("theme", "menu")) if not level.is_empty() else "menu"
    var sky := Color("#1d2c46")
    var horizon := Color("#345875")
    var ground := Color("#a95e43")
    var leaf := Color("#247265")
    if theme == "kabasa":
        sky = Color("#35597a"); horizon = Color("#6e7f69"); ground = Color("#b86c42")
    elif theme == "luanda":
        sky = Color("#2e6680"); horizon = Color("#d19667"); ground = Color("#b96c48")
    elif theme == "kwanza":
        sky = Color("#153d50"); horizon = Color("#17685f"); ground = Color("#8a5f3d")
    elif theme == "matamba":
        sky = Color("#31564a"); horizon = Color("#6d7950"); ground = Color("#aa6c43")
    elif theme == "kombi":
        sky = Color("#283c58"); horizon = Color("#6c6b69"); ground = Color("#85543c")
    elif theme == "paz":
        sky = Color("#5c86a0"); horizon = Color("#98ab76"); ground = Color("#ba7b4a")
    draw_rect(Rect2(0, 0, world_width, 270), sky)
    draw_rect(Rect2(0, 155, world_width, 115), horizon)
    for i in range(0, int(world_width), 80):
        var mountain_h := 22.0 + float((i / 80) % 3) * 12.0
        draw_colored_polygon(PackedVector2Array([Vector2(i, 190), Vector2(i + 45, 190 - mountain_h), Vector2(i + 90, 190)]), horizon.darkened(0.18))
    if not level.is_empty():
        for i in range(0, int(world_width), 120):
            draw_rect(Rect2(i + 22, 184, 3, 34), leaf.darkened(0.1))
            draw_circle(Vector2(i + 23, 181), 13, leaf)
            draw_circle(Vector2(i + 11, 188), 8, leaf)
        for p in platforms:
            var rect := Rect2(float(p[0]), float(p[1]), float(p[2]), float(p[3]))
            draw_rect(rect, Color("#3e2d2d"))
            draw_rect(Rect2(rect.position + Vector2(0, 2), Vector2(rect.size.x, maxf(3.0, rect.size.y - 2))), ground)
            draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), Color("#e0a45b"))
            for x in range(int(rect.position.x) + 10, int(rect.end.x), 24):
                draw_rect(Rect2(x, rect.position.y + 7, 8, 2), ground.darkened(0.18))
        for hazard in hazards:
            var hrect := Rect2(float(hazard["x"]), float(hazard["y"]), float(hazard["w"]), float(hazard["h"]))
            draw_rect(hrect, Color("#54323a"))
            if str(hazard.get("type", "")) == "estacas":
                for x in range(int(hrect.position.x), int(hrect.end.x), 8):
                    draw_colored_polygon(PackedVector2Array([Vector2(x, hrect.end.y), Vector2(x + 4, hrect.position.y), Vector2(x + 8, hrect.end.y)]), Color("#d5ad70"))
        for point in level.get("checkpoints", []):
            var x := float(point[0]) if point is Array else float(point.get("x", 0))
            draw_rect(Rect2(x - 2, 202, 4, 33), Color("#50353a"))
            draw_circle(Vector2(x, 201), 9, gold)
            draw_circle(Vector2(x, 201), 5, Color("#8b4b3b"))
            draw_line(Vector2(x - 5, 201), Vector2(x + 5, 201), Color("#f7dc8d"), 1)
        draw_flag(Vector2(float(level.get("goal_x", 2000)), 205))
        for item in collectibles:
            if bool(item.get("taken", false)):
                continue
            draw_item(item)
        for enemy in enemies:
            draw_enemy(enemy)
        for projectile in projectiles:
            draw_line(Vector2(float(projectile["x"]), float(projectile["y"])), Vector2(float(projectile["x"]) - 8.0 * float(projectile["dir"]), float(projectile["y"])), Color("#e6c48f"), 2)

func draw_flag(pos: Vector2) -> void:
    draw_rect(Rect2(pos.x, pos.y - 25, 2, 30), Color("#432d32"))
    draw_colored_polygon(PackedVector2Array([Vector2(pos.x + 2, pos.y - 25), Vector2(pos.x + 22, pos.y - 20), Vector2(pos.x + 2, pos.y - 13)]), gold)
    draw_circle(Vector2(pos.x, pos.y - 29), 3, cream)

func draw_item(item: Dictionary) -> void:
    var pos := Vector2(float(item["x"]), float(item["y"]))
    var kind := str(item.get("type", ""))
    if kind == "nzimbu":
        draw_circle(pos, 6, cream)
        draw_circle(pos, 3, Color("#c1a06c"))
        draw_line(pos + Vector2(-1, -2), pos + Vector2(2, 2), Color("#8c6d56"), 1)
    elif kind == "card":
        draw_rect(Rect2(pos - Vector2(7, 9), Vector2(14, 18)), Color("#e4c67e"))
        draw_rect(Rect2(pos - Vector2(5, 7), Vector2(10, 2)), Color("#7d4b43"))
        draw_line(pos + Vector2(-4, -1), pos + Vector2(4, -1), Color("#7d4b43"), 1)
        draw_line(pos + Vector2(-4, 3), pos + Vector2(3, 3), Color("#7d4b43"), 1)
    elif kind == "captive":
        draw_circle(pos + Vector2(0, -8), 4, Color("#8b4b3b"))
        draw_rect(Rect2(pos.x - 5, pos.y - 4, 10, 10), Color("#d1a04e"))
        draw_rect(Rect2(pos.x - 8, pos.y - 10, 16, 18), Color(0.9, 0.82, 0.55, 0.24), false, 1)
    elif kind == "ally":
        draw_circle(pos + Vector2(0, -8), 4, Color("#8b4b3b"))
        draw_rect(Rect2(pos.x - 5, pos.y - 4, 10, 10), green)
        draw_line(pos + Vector2(6, -12), pos + Vector2(12, -3), gold, 2)
    elif kind == "material":
        draw_rect(Rect2(pos - Vector2(7, 6), Vector2(14, 12)), Color("#c18a4c"))
        draw_line(pos + Vector2(-5, -3), pos + Vector2(5, -3), Color("#6c4638"), 2)
    elif kind == "quiver":
        draw_rect(Rect2(pos - Vector2(5, 9), Vector2(10, 18)), Color("#754537"))
        for x in range(-3, 4, 3):
            draw_line(pos + Vector2(x, -8), pos + Vector2(x + 2, -14), cream, 1)

func draw_enemy(enemy: Dictionary) -> void:
    if not bool(enemy.get("alive", true)):
        draw_circle(Vector2(float(enemy["x"]), float(enemy["y"]) - 3), 5, Color(0.93, 0.82, 0.56, 0.42))
        draw_circle(Vector2(float(enemy["x"]) + 8, float(enemy["y"]) - 6), 3, Color(0.93, 0.82, 0.56, 0.34))
        return
    var pos := Vector2(float(enemy["x"]), float(enemy["y"]))
    var kind := str(enemy.get("type", "guarda"))
    if kind == "patrulha":
        var dir := float(enemy.get("dir", 1.0))
        var vision := float(enemy.get("vision", 90.0))
        var tip := pos + Vector2(dir * vision, -16)
        draw_colored_polygon(PackedVector2Array([pos + Vector2(0, -20), pos + Vector2(dir * vision, -28), tip, pos + Vector2(dir * vision, 4)]), Color(0.96, 0.83, 0.38, 0.10))
        draw_line(pos + Vector2(0, -19), pos + Vector2(dir * vision, -28), Color(0.96, 0.83, 0.38, 0.35), 1)
    var body := Color("#74505a")
    if kind in ["canhao", "campeao"]:
        body = Color("#8f5b4c")
    draw_circle(pos + Vector2(0, -13), 5, Color("#8b4b3b"))
    draw_rect(Rect2(pos.x - 6, pos.y - 9, 12, 13), body)
    draw_rect(Rect2(pos.x - 5, pos.y + 4, 4, 7), ink)
    draw_rect(Rect2(pos.x + 1, pos.y + 4, 4, 7), ink)
    if enemy.get("boss", false):
        draw_rect(Rect2(pos.x - 8, pos.y - 22, 16, 3), gold)
    if kind == "canhao":
        draw_rect(Rect2(pos.x + 4, pos.y - 7, 13, 5), Color("#292b32"))

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_SIZE_CHANGED:
        queue_redraw()
