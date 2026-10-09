extends CharacterBody2D

signal attack_requested
signal bow_requested
signal jumped
signal fell

var speed := 86.0
var acceleration := 520.0
var friction := 760.0
var gravity := 520.0
var jump_power := 176.0
var jump_cut := 70.0
var coyote_time := 0.10
var jump_buffer := 0.12
var coyote_left := 0.0
var jump_buffer_left := 0.0
var facing := 1.0
var stage_index := 0
var alive := true
var axe_unlocked := false
var bow_unlocked := false
var can_shoot := true
var was_jump := false
var was_attack := false
var was_bow := false
var anim_time := 0.0
var invulnerable := 0.0

func _ready() -> void:
    collision_layer = 2
    collision_mask = 1
    var shape := CollisionShape2D.new()
    var capsule := CapsuleShape2D.new()
    capsule.radius = 6.0
    capsule.height = 22.0
    shape.shape = capsule
    shape.position = Vector2(0, -11)
    add_child(shape)
    queue_redraw()

func setup(index: int, axe: bool, bow: bool) -> void:
    stage_index = index
    axe_unlocked = axe
    bow_unlocked = bow
    queue_redraw()

func _physics_process(delta: float) -> void:
    if not alive:
        return
    anim_time += delta
    invulnerable = maxf(0.0, invulnerable - delta)
    var touch_left := false
    var touch_right := false
    var touch_jump := false
    var touch_attack := false
    var touch_bow := false
    var parent := get_parent()
    if parent != null:
        touch_left = bool(parent.get("touch_left"))
        touch_right = bool(parent.get("touch_right"))
        touch_jump = bool(parent.get("touch_jump"))
        touch_attack = bool(parent.get("touch_attack"))
        touch_bow = bool(parent.get("touch_bow"))

    var keyboard_left := Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT)
    var keyboard_right := Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)
    if parent != null and parent.has_method("key_down"):
        keyboard_left = bool(parent.key_down("left", KEY_A)) or Input.is_key_pressed(KEY_LEFT)
        keyboard_right = bool(parent.key_down("right", KEY_D)) or Input.is_key_pressed(KEY_RIGHT)
    var direction := float(int(keyboard_right) - int(keyboard_left))
    if absf(direction) < 0.05:
        direction = float(int(touch_right) - int(touch_left))
    if absf(direction) > 0.05:
        velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
        facing = signf(direction)
    else:
        velocity.x = move_toward(velocity.x, 0.0, friction * delta)

    var jump_pressed := Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_UP) or touch_jump
    if parent != null and parent.has_method("key_down"):
        jump_pressed = bool(parent.key_down("jump", KEY_SPACE)) or Input.is_key_pressed(KEY_UP) or touch_jump
    var jump_started := jump_pressed and not was_jump
    var jump_released := (not jump_pressed) and was_jump
    was_jump = jump_pressed
    if jump_started:
        jump_buffer_left = jump_buffer
    else:
        jump_buffer_left = maxf(0.0, jump_buffer_left - delta)

    if is_on_floor():
        coyote_left = coyote_time
    else:
        coyote_left = maxf(0.0, coyote_left - delta)
        velocity.y += gravity * delta

    if jump_buffer_left > 0.0 and coyote_left > 0.0:
        velocity.y = -jump_power
        jump_buffer_left = 0.0
        coyote_left = 0.0
        jumped.emit()
    if jump_released and velocity.y < -jump_cut:
        velocity.y = -jump_cut

    var attack_pressed := Input.is_key_pressed(KEY_J) or touch_attack
    var bow_pressed := Input.is_key_pressed(KEY_K) or touch_bow
    if parent != null and parent.has_method("key_down"):
        attack_pressed = bool(parent.key_down("attack", KEY_J)) or touch_attack
        bow_pressed = bool(parent.key_down("bow", KEY_K)) or touch_bow
    if attack_pressed and not was_attack:
        attack_requested.emit()
    if bow_pressed and not was_bow:
        bow_requested.emit()
    was_attack = attack_pressed
    was_bow = bow_pressed

    move_and_slide()
    if global_position.y > 330.0:
        fell.emit()
    queue_redraw()

func respawn(at: Vector2) -> void:
    global_position = at
    velocity = Vector2.ZERO
    alive = true
    invulnerable = 1.0
    visible = true
    queue_redraw()

func hurt() -> void:
    if invulnerable > 0.0:
        return
    invulnerable = 1.2
    velocity = Vector2(-facing * 70.0, -90.0)

func _draw() -> void:
    var skin := Color("#8b4b3b")
    var cloth := Color("#d9a441")
    var accent := Color("#226b63")
    var dark := Color("#2b1b2a")
    if stage_index == 0:
        cloth = Color("#d97843")
        accent = Color("#5c8e74")
    elif stage_index >= 5:
        cloth = Color("#b6a16e")
        accent = Color("#7e4f3e")
    if not alive:
        draw_ellipse_shape(Vector2(0, -8), Vector2(13, 4), Color("#e5c08b"))
        return
    if invulnerable > 0.0 and int(anim_time * 16.0) % 2 == 0:
        return
    var bob := 0.0 if not is_on_floor() else sin(anim_time * 14.0) * 0.7
    draw_rect(Rect2(-6, -18 + bob, 12, 12), cloth)
    draw_rect(Rect2(-7, -10 + bob, 14, 5), accent)
    draw_rect(Rect2(-5, -25 + bob, 10, 9), skin)
    draw_rect(Rect2(-6, -27 + bob, 12, 4), dark)
    draw_rect(Rect2(-3, -25 + bob, 2, 2), Color("#f6dfb4"))
    draw_rect(Rect2(1, -25 + bob, 2, 2), Color("#f6dfb4"))
    draw_rect(Rect2(-5, -5 + bob, 4, 7), dark)
    draw_rect(Rect2(1, -5 + bob, 4, 7), dark)
    if axe_unlocked:
        var axe_x := 10.0 * facing
        draw_line(Vector2(axe_x, -15 + bob), Vector2(axe_x + 5.0 * facing, -25 + bob), Color("#51372d"), 2.0)
        draw_line(Vector2(axe_x + 3.0 * facing, -25 + bob), Vector2(axe_x + 8.0 * facing, -23 + bob), Color("#c8d0c0"), 2.0)
    elif bow_unlocked:
        draw_arc(Vector2(-7 * facing, -14 + bob), 7.0, -1.1, 1.1, 8, Color("#e6c48f"), 1.3)
        draw_line(Vector2(-7 * facing, -20 + bob), Vector2(-7 * facing, -8 + bob), Color("#e6c48f"), 1.0)

func draw_ellipse_shape(center: Vector2, radius: Vector2, color: Color) -> void:
    var points := PackedVector2Array()
    for i in range(16):
        var angle := TAU * float(i) / 16.0
        points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
    draw_colored_polygon(points, color)
