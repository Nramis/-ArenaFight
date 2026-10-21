class_name RamisUltimate
extends RefCounted

# The simulation owns the clock. Renderers never change damage, positions or RNG.
const TOTAL := 204
const IMPACT := 114
const DRIVE := 64
const SLAM := 96
const RECOVER := 144
var f: Fighter
var age := -1
var source: Fighter
var target: Fighter
var direction := 1
var start := Vector2.ZERO
var impact := Vector2.ZERO
var crater_active := false
var struck := false

func _init(owner_fighter: Fighter) -> void:
    f = owner_fighter

func active() -> bool:
    return age >= 0 and age < TOTAL

func locked() -> bool:
    return active() or (is_instance_valid(source) and source.abilities.expansion.hero.active())

func begin(victim: Fighter) -> bool:
    if f.roster_name() != "ramis" or active() or f.health <= 0 or not is_instance_valid(victim) or victim.health <= 0:
        return false
    # Clear ordinary casts before establishing the paired cinematic lock.
    for fighter: Fighter in [f, victim]:
        fighter.abilities.interrupt_cast()
        fighter.current_move = null
        fighter.attack_buffer = ""
        fighter.attack_buffer_frames = 0
        fighter.throw_pressed = false
        fighter.hitstop_frames = 0
        fighter.vel = Vector2.ZERO
        fighter.state_machine.force_state("Idle")
    f.abilities.expansion.bald = true
    f.abilities.expansion.one_punch_ready = false
    target = victim
    victim.abilities.expansion.hero.source = f
    direction = f.facing()
    impact = Vector2(clampf(victim.position.x, 105, 279), f.ground_y)
    start = Vector2(impact.x - direction * 70, f.ground_y)
    f.position = start
    target.position = impact
    f.on_ground = true
    target.on_ground = true
    target.visible = false
    age = 0
    struck = false
    crater_active = false
    var scene := Node2D.new()
    scene.set_script(load("res://fx/ramis_ultimate_scene.gd"))
    scene.attacker = f
    scene.victim = target
    f.get_parent().add_child(scene)
    f.emit_sound("buff")
    return true

func tick() -> void:
    if not active():
        return
    if not is_instance_valid(target) or f.health <= 0:
        cancel()
        return
    age += 1
    f.vel = Vector2.ZERO
    target.vel = Vector2.ZERO
    var run := smoothstep(0.0, 1.0, clampf((age - DRIVE) / 32.0, 0, 1))
    f.position = start.lerp(Vector2(impact.x - direction * 30, impact.y), run)
    target.position = impact
    if age >= SLAM and age < IMPACT:
        target.position.y -= sin((age - SLAM) / float(IMPACT - SLAM) * PI * .5) * 58
    elif age >= IMPACT:
        target.position.y += minf(18, (age - IMPACT) * 2)
    if age == IMPACT and not struck:
        struck = true
        crater_active = true
        var damage := target.health
        target.health = 0
        target.last_damage = damage
        target.last_hit_blocked = false
        target.last_counter_hit = false
        target.combo_count = 1
        target.combo_damage = damage
        target.combo_display_frames = 90
        target.emit_blood(mini(180, damage), direction)
        f.emit_sound("combo_finish")
        f.abilities.expansion.one_punch_victory = true
        if f.get_parent().has_method("_on_hit"):
            f.get_parent()._on_hit(target)
            f.get_parent()._shake = 24
    if age >= TOTAL:
        # The scene retains the buried victim and crater until the round resets.
        f.position = Vector2(impact.x - direction * 40, impact.y)
        f.current_move = null
        f.state_machine.force_state("Idle")
        target.state_machine.force_state("Knockdown")

func cancel() -> void:
    age = -1
    if is_instance_valid(target):
        target.visible = true
        target.position.y = target.ground_y
        target.on_ground = true
        target.abilities.expansion.hero.source = null
    target = null
    crater_active = false
    struck = false

func reset() -> void:
    if is_instance_valid(source) and source.abilities.expansion.hero.active():
        source.abilities.expansion.hero.cancel()
    source = null
    cancel()
    direction = 1
    start = Vector2.ZERO
    impact = Vector2.ZERO

func digest() -> Array:
    return [age, source.team if is_instance_valid(source) else -1, target.team if is_instance_valid(target) else -1, direction, start.x, start.y, impact.x, impact.y, crater_active, struck]
