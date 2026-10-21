class_name RinatAbilities
extends RefCounted

# Gameplay is advanced only by the owning Fighter's deterministic 60 Hz tick.
const CHAIN_WINDUP := 24
const CHAIN_FLIGHT := 24
const PULL_DURATION := 18
const BIND_DURATION := 120
const DRINK_DURATION := 36
const MASTER_DURATION := 900
const MASTER_COOLDOWN := 1200
const SMOKE_WINDUP := 18
const SMOKE_DURATION := 120
const CHANTS := ["Малайлар, әйдә, бля! Биергә!", "Әй, малайлар! Кайда сез, бля?", "Малайлар, җырлыйбыз, бля! Әйдә!"]
var fighter: Fighter
var chain_frames := 0
var chain_direction := 1
var bound_frames := 0
var pull_frames := 0
var bound_source: Fighter
var drink_frames := 0
var master_frames := 0
var tear_timer := 0
var tear_frames := 0
var shirt_torn := false
var chant_timer := 0
var chant_frames := 0
var chant_variant := 0
var smoke_windup := 0
var smoke_frames := 0
var smoke_clock := 0

func _init(owner_fighter: Fighter) -> void:
    fighter = owner_fighter

func activate(slot: int) -> void:
    var a := fighter.abilities
    a.pose_kind = ["rinat_chain", "rinat_elixir", "rinat_vape"][slot]
    a.effect_name = ["ТЫ ОРЛОВ? ИДИ СЮДА!", "ПЬЯНЫЙ МАСТЕР", "БЕЛЫЙ ДЫМ"][slot]
    match slot:
        0:
            chain_direction = fighter.facing()
            chain_frames = CHAIN_WINDUP + CHAIN_FLIGHT
            a.pose_frames = chain_frames + 8
            fighter.emit_sound("rinatChain")
        1:
            drink_frames = DRINK_DURATION
            a.pose_frames = DRINK_DURATION
            a.cooldowns[1] = DRINK_DURATION + MASTER_DURATION + MASTER_COOLDOWN
            fighter.emit_sound("item")
        2:
            smoke_windup = SMOKE_WINDUP
            a.pose_frames = 32
            fighter.emit_sound("rinatVape")

func locked() -> bool:
    return bound_frames > 0

func tick() -> void:
    _tick_binding()
    _tick_pull_input()
    tear_frames = maxi(0, tear_frames - 1)
    chant_frames = maxi(0, chant_frames - 1)
    if master_frames > 0:
        master_frames -= 1
        tear_timer -= 1
        chant_timer -= 1
        if tear_timer <= 0:
            shirt_torn = true
            tear_frames = 36
            tear_timer = randi_range(150, 270)
            fighter.emit_sound("rinatTear")
        if chant_timer <= 0:
            chant_variant = randi_range(0, CHANTS.size() - 1)
            chant_frames = 100
            chant_timer = randi_range(180, 240)
            fighter.emit_sound("rinatChant" + str(chant_variant))
            var target := fighter.opponent
            if is_instance_valid(target) and not target.is_invulnerable():
                target.abilities.slow_strength = maxf(0.30, target.abilities.slow_strength)
                target.abilities.slow_frames = maxi(90, target.abilities.slow_frames)
        if master_frames == 0:
            shirt_torn = false
            tear_frames = 0
            chant_frames = 0
    if drink_frames > 0:
        drink_frames -= 1
        if drink_frames == 0:
            master_frames = MASTER_DURATION
            tear_timer = randi_range(80, 160)
            chant_timer = 30
            fighter.abilities.flash_frames = 30
    if chain_frames > 0:
        chain_frames -= 1
        if chain_frames <= CHAIN_FLIGHT:
            _catch_chain(1.0 - chain_frames / float(CHAIN_FLIGHT))
    if smoke_frames > 0:
        smoke_clock += 1
        smoke_frames -= 1
        if smoke_clock % 30 == 0:
            var target := fighter.opponent
            if is_instance_valid(target) and target.health > 0 and not target.is_invulnerable():
                # A cloud is damage over time, without repeated hitstun or combo resets.
                target.health = maxi(0, target.health - 6)
    if smoke_windup > 0:
        smoke_windup -= 1
        if smoke_windup == 0:
            smoke_frames = SMOKE_DURATION
            smoke_clock = 0

func _catch_chain(progress: float = 1.0) -> void:
    var target := fighter.opponent
    if not is_instance_valid(target) or target.health <= 0 or target.is_invulnerable():
        return
    var reach := 340.0 * clampf(progress, 0, 1)
    var origin := fighter.position + Vector2(0, -65)
    var segment := Rect2(Vector2(origin.x if chain_direction > 0 else origin.x - reach, origin.y - 14), Vector2(reach, 37))
    if not segment.intersects(target.hurtbox_rect()):
        return
    chain_frames = 0
    fighter.abilities.pose_frames = 0
    var move := MoveData.new()
    move.move_name = "RinatChain"
    move.damage = int(round(35 * fighter.abilities.damage_multiplier()))
    move.pushback = 0
    move.hitstun = 6
    if target.is_blocking(move):
        target.receive_block(move, chain_direction)
    else:
        target.receive_hit(move, chain_direction)
        target.abilities.rinat.bound_source = fighter
        target.abilities.rinat.pull_frames = 0
        target.abilities.rinat.bound_frames = BIND_DURATION
        target.vel = Vector2.ZERO
        target.current_move = null
        target.hitstun_frames = 0
        target.state_machine.force_state("Idle")
    fighter.get_parent()._on_hit(target)

func _tick_binding() -> void:
    if bound_frames == 0:
        return
    if not is_instance_valid(bound_source) or bound_source.health <= 0 or fighter.health <= 0:
        release_binding()
        return
    fighter.vel = Vector2.ZERO
    fighter.position.y = fighter.ground_y
    fighter.on_ground = true
    bound_frames -= 1
    if bound_frames == 0:
        release_binding()


func has_bound_target() -> bool:
    return is_instance_valid(fighter.opponent) and fighter.opponent.abilities != null and fighter.opponent.abilities.rinat.bound_source == fighter and fighter.opponent.abilities.rinat.bound_frames > 0

func _tick_pull_input() -> void:
    if not has_bound_target():
        return
    var held := fighter.input.lp or fighter.input.mp or fighter.input.hp or fighter.input.lk or fighter.input.mk or fighter.input.hk
    if fighter.input_source is AIInput:
        held = true
    if not held:
        return
    var target := fighter.opponent
    var destination := clampf(fighter.position.x + chain_direction * 48, fighter.wall_left, fighter.wall_right)
    target.position.x = move_toward(target.position.x, destination, 3.4)
    target.abilities.rinat.pull_frames += 1
    fighter.attack_buffer = ""
    fighter.attack_buffer_frames = 0

func release_binding() -> void:
    bound_frames = 0
    pull_frames = 0
    bound_source = null

func interrupt() -> void:
    if has_bound_target():
        fighter.opponent.abilities.rinat.release_binding()
    chain_frames = 0
    smoke_windup = 0
    if drink_frames > 0:
        drink_frames = 0
        fighter.abilities.cooldowns[1] = MASTER_COOLDOWN

func reset() -> void:
    interrupt()
    release_binding()
    master_frames = 0
    tear_timer = 0
    tear_frames = 0
    shirt_torn = false
    chant_timer = 0
    chant_frames = 0
    chant_variant = 0
    chain_direction = 1
    smoke_frames = 0
    smoke_clock = 0

func digest() -> Array:
    return [chain_frames, chain_direction, bound_frames, pull_frames, bound_source.team if is_instance_valid(bound_source) else -1, drink_frames, master_frames, tear_timer, tear_frames, shirt_torn, chant_timer, chant_frames, chant_variant, smoke_windup, smoke_frames, smoke_clock]
