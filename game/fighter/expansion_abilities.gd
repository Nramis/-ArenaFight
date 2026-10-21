class_name ExpansionAbilities
extends RefCounted

# Round-local inventory and auxiliary moves. Only the fixed simulation tick writes these.
const WATER_COOLDOWN := 900
const WATER_WINDUP := 36
const WATER_ACTIVE := 30
const WATER_TOTAL := 84
const HOLD_DURATION := 390
const COUNTER_DAMAGE := 300
const COUNTER_DURATION := 96
const COUNTER_OPEN_AGE := 60
const COUNTER_CLOSE_REMAINING := 60
const COUNTER_BUTTONS := ["lp", "mp", "hp", "lk", "mk", "hk"]
const SHAVE_DURATION := 120
const SHAVE_COOLDOWN := 600
var hero: RamisUltimate
var f: Fighter
var auxiliary_cd := 0
var water_frames := 0
var cheese_used := false
var cheese_mode := false
var cheese_remaining := 12
var cheese_recovery := 0
var cheese_pose := 0
var assist_variant := -1
var hold_frames := 0
var hold_source: Fighter
var ai_clock := 0
var hold_counter_button := ""
var hold_counter_used := false
var counter_frames := 0
var shave_frames := 0
var bald := false
var one_punch_ready := false
var punch_flash := 0
var one_punch_victory := false

func _init(owner_fighter: Fighter) -> void:
    f = owner_fighter
    hero = RamisUltimate.new(owner_fighter)

func interaction_locked() -> bool:
    return hero.locked() or hold_frames > 0 or (is_instance_valid(hold_source) and hold_source.abilities.expansion.hold_frames > 0)

func locked() -> bool:
    return water_frames > 0 or shave_frames > 0 or interaction_locked()

func neutral() -> bool:
    return not f.frozen and f.health > 0 and f.on_ground and f.state_machine.current_state != null and str(f.state_machine.current_state.name) in ["Idle", "Walk", "Crouch"]

func activate_auxiliary() -> bool:
    if not neutral() or f.abilities.locked():
        return false
    match f.roster_name():
        "nikita":
            if auxiliary_cd > 0:
                return false
            auxiliary_cd = WATER_COOLDOWN
            water_frames = WATER_TOTAL
            f.abilities.effect_name = "СУЙТОН · РЕЖУЩАЯ СТРУЯ"
            f.emit_sound("waterSeal")
        "ramis":
            if auxiliary_cd > 0 or one_punch_ready:
                return false
            auxiliary_cd = SHAVE_COOLDOWN
            shave_frames = SHAVE_DURATION
            f.abilities.maris_frames = 0
            f.abilities.effect_name = "БРИТЬЁ · СБЕЙ ПРИЁМ!"
            f.emit_sound("item")
        "bigboss":
            if cheese_remaining == 0 and not cheese_mode:
                return false
            cheese_used = true
            cheese_mode = not cheese_mode
            cheese_pose = 30
            f.abilities.effect_name = "СЫРКИ АЛЕКСАНДРОВ · %d/12" % cheese_remaining
            f.emit_sound("item")
        "mavrin":
            if auxiliary_cd > 0:
                return false
            auxiliary_cd = 720
            assist_variant = randi_range(0, Roster.IDS.size() - 1)
            f.abilities.pose_kind = "ket"
            f.abilities.pose_frames = 36
            f.abilities.effect_name = "КЭТ! · " + Roster.NAMES[Roster.IDS[assist_variant]]
            f.emit_sound("mavrinKet")
            _effect("assist", assist_variant)
        _:
            return false
    f.vel = Vector2.ZERO
    f.current_move = null
    f.attack_buffer = ""
    f.attack_buffer_frames = 0
    f.state_machine.force_state("Idle")
    return true

func activate_hold() -> bool:
    if hold_frames > 0:
        if counter_frames > 0:
            return false
        if hold_frames < HOLD_DURATION - 30:
            release_hold()
        return true
    var target := f.opponent
    if f.roster_name() != "mavrin" or not is_instance_valid(target) or target.roster_name() != "polina":
        return false
    if not neutral() or f.abilities.locked() or target.health <= 0 or target.is_invulnerable() or target.abilities.locked() or not target.on_ground:
        return false
    if absf(target.position.x - f.position.x) > 72:
        return false
    hold_frames = HOLD_DURATION
    hold_counter_used = false
    # Roll once per grab in the fixed simulation. Presentation never consumes RNG.
    hold_counter_button = COUNTER_BUTTONS[randi_range(0, 5)] if randi_range(0, 1) == 1 else ""
    target.abilities.expansion.hold_source = f
    for fighter: Fighter in [f, target]:
        fighter.vel = Vector2.ZERO
        fighter.current_move = null
        fighter.throw_pressed = false
        fighter.attack_buffer = ""
        fighter.attack_buffer_frames = 0
        fighter.state_machine.force_state("Idle")
    f.emit_sound("mavrinPolina")
    return true

func tick() -> void:
    hero.tick()
    ai_clock += 1
    auxiliary_cd = maxi(0, auxiliary_cd - 1)
    punch_flash = maxi(0, punch_flash - 1)
    if shave_frames > 0:
        shave_frames -= 1
        f.vel = Vector2.ZERO
        if shave_frames == 0:
            bald = true
            one_punch_ready = true
            f.abilities.effect_name = "ОДИН УДАР · ГОТОВ"
            f.emit_sound("buff")
    cheese_recovery = maxi(0, cheese_recovery - 1)
    cheese_pose = maxi(0, cheese_pose - 1)
    if water_frames > 0:
        water_frames -= 1
        f.vel = Vector2.ZERO
        if water_frames == WATER_TOTAL - WATER_WINDUP:
            f.emit_sound("waterJet")
            _effect("water")
    if hold_frames > 0:
        if counter_frames > 0:
            _tick_counter()
        else:
            hold_frames -= 1
            if not is_instance_valid(f.opponent) or f.opponent.health <= 0 or f.health <= 0 or hold_frames == 0:
                release_hold()
            else:
                var age := HOLD_DURATION - hold_frames
                if age == 90:
                    f.emit_sound("polinaReply")
                f.vel = Vector2.ZERO
                f.opponent.vel = Vector2.ZERO
                var side := f.facing()
                var destination := Vector2(clampf(f.position.x + side * 47, f.wall_left, f.wall_right), f.ground_y - 35 + sin(age * 0.5) * 7)
                f.opponent.position = destination
                f.opponent.on_ground = false
    elif is_instance_valid(hold_source):
        var holder := hold_source.abilities.expansion
        if holder.hold_frames == 0:
            hold_source = null
            f.position.y = f.ground_y
            f.on_ground = true
        elif holder.counter_available():
            if f.input_source is AIInput:
                if HOLD_DURATION - holder.hold_frames >= 120:
                    holder.attempt_counter(holder.hold_counter_button)
            elif not f.just_pressed.is_empty():
                holder.attempt_counter(str(f.just_pressed[0]))
    if f.input_source is HumanInput:
        var prefix: String = f.input_source.player_prefix
        if f.abilities._action_pressed(prefix, "extra2"):
            activate_hold()
        if f.abilities._action_pressed(prefix, "extra1"):
            activate_auxiliary()
    elif f.input_source is AIInput and not f.abilities.locked():
        if auxiliary_cd == 0 and (ai_clock + f.team * 31) % 181 == 0:
            if f.roster_name() != "bigboss" or not cheese_mode:
                activate_auxiliary()
    if cheese_mode and (not f.just_pressed.is_empty() or (f.input_source is AIInput and cheese_recovery == 0)):
        throw_cheese()

func throw_cheese() -> bool:
    if not cheese_mode or cheese_remaining <= 0 or cheese_recovery > 0 or not neutral() or f.abilities.locked():
        return false
    cheese_remaining -= 1
    cheese_recovery = 26
    cheese_pose = 24
    f.attack_buffer = ""
    f.attack_buffer_frames = 0
    f.emit_sound("swing")
    _effect("cheese")
    # Empty tray stays equipped until put away, preventing a surprise normal attack.
    return true

func put_away_empty_tray() -> void:
    if cheese_mode and cheese_remaining == 0:
        cheese_mode = false

func _effect(kind: String, variant: int = 0) -> void:
    var effect := Node2D.new()
    effect.set_script(preload("res://fx/expansion_effect.gd"))
    effect.kind = kind
    effect.attacker = f
    effect.target = f.opponent
    effect.variant = variant
    effect.direction = f.facing()
    f.get_parent().add_child(effect)

func release_hold() -> void:
    hold_frames = 0
    counter_frames = 0
    hold_counter_button = ""
    hold_counter_used = false
    if is_instance_valid(f.opponent) and f.opponent.abilities.expansion.hold_source == f:
        var target := f.opponent
        target.abilities.expansion.hold_source = null
        target.position.y = target.ground_y
        target.on_ground = true
        target.vel = Vector2.ZERO

func interrupt() -> void:
    if hero.active():
        hero.cancel()
    water_frames = 0
    shave_frames = 0
    release_hold()

func reset() -> void:
    hero.reset()
    release_hold()
    hold_source = null
    auxiliary_cd = 0
    water_frames = 0
    cheese_used = false
    cheese_mode = false
    cheese_remaining = 12
    cheese_recovery = 0
    cheese_pose = 0
    assist_variant = -1
    ai_clock = 0
    shave_frames = 0
    bald = false
    one_punch_ready = false
    punch_flash = 0
    one_punch_victory = false

func counter_available() -> bool:
    return hold_frames > COUNTER_CLOSE_REMAINING and hold_frames <= HOLD_DURATION - COUNTER_OPEN_AGE and counter_frames == 0 and not hold_counter_used and not hold_counter_button.is_empty()

func attempt_counter(button: String) -> bool:
    if not counter_available():
        return false
    hold_counter_used = true
    if button != hold_counter_button:
        return false
    counter_frames = COUNTER_DURATION
    f.attack_buffer = ""
    f.opponent.attack_buffer = ""
    f.opponent.emit_sound("swing_heavy")
    return true

func _tick_counter() -> void:
    counter_frames -= 1
    f.vel = Vector2.ZERO
    f.opponent.vel = Vector2.ZERO
    if counter_frames == COUNTER_DURATION - 30:
        # A scripted paired strike: normal hit reception would cancel the joint pose.
        f.last_damage = COUNTER_DAMAGE
        f.last_hit_blocked = false
        f.combo_count = 1
        f.combo_damage = COUNTER_DAMAGE
        f.combo_display_frames = 90
        f.health = maxi(0, f.health - COUNTER_DAMAGE)
        f.emit_blood(COUNTER_DAMAGE, -f.facing())
        f.emit_sound("counter")
        if f.get_parent().has_method("_on_hit"):
            f.get_parent()._on_hit(f)
    if counter_frames == 0 or f.health <= 0:
        release_hold()
        f.knockdown_frames = 45
        f.state_machine.force_state("Knockdown")

func counter_button_label() -> String:
    if not is_instance_valid(f.opponent):
        return ""
    var network := f.get_node_or_null("/root/NetSession")
    var prefix := "p2" if f.opponent.name == "Player2" and (network == null or not network.enabled) else "p1"
    var labels := {"lp":"Р1", "mp":"Р2", "hp":"Р3", "lk":"Н1", "mk":"Н2", "hk":"Н3"}
    var label: String = labels.get(hold_counter_button, "")
    for event in InputMap.action_get_events(prefix + "_" + hold_counter_button):
        if event is InputEventKey:
            var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
            return OS.get_keycode_string(code) + " / " + label
    return label

func consume_one_punch() -> bool:
    if not one_punch_ready:
        return false
    one_punch_ready = false
    punch_flash = 30
    f.emit_sound("swing_heavy")
    return true

func status() -> String:
    if hero.active():
        return "СЕРЬЁЗНЫЙ УДАР · РАМИС"
    if is_instance_valid(hero.source) and hero.locked():
        return "ВБИВАНИЕ В ЗЕМЛЮ"
    if counter_frames > 0:
        return "ПОЛИНА · КОНТРАТАКА!"
    if hold_frames > 0:
        return "ПОЛИНА · ЗАХВАТ"
    if is_instance_valid(hold_source):
        var holder := hold_source.abilities.expansion
        if holder.counter_available():
            return "НАЖМИ " + holder.counter_button_label() + " · КОНТРАТАКА"
        return "В ЗАХВАТЕ"
    if f.roster_name() == "ramis":
        var network := f.get_node_or_null("/root/NetSession")
        var key := "−" if f.name == "Player2" and (network == null or not network.enabled) else "T"
        if shave_frames > 0:
            return "БРЕЕТСЯ %.1f · СБЕЙ УДАРОМ!" % (shave_frames / 60.0)
        if one_punch_ready:
            return "ЛЫСЫЙ ГЕРОЙ · ОДИН УДАР!"
        return key + " · БРИТЬЁ" + (" ГОТОВО" if auxiliary_cd == 0 else " %.1f" % (auxiliary_cd / 60.0))
    if water_frames > 0:
        return "СУЙТОН · ПЕЧАТИ" if water_frames > WATER_TOTAL - WATER_WINDUP else "РЕЖУЩАЯ СТРУЯ"
    if f.roster_name() == "bigboss":
        return ("СЫРКИ %d/12 · T УБРАТЬ" if cheese_mode else "T · СЫРКИ %d/12") % cheese_remaining
    if f.roster_name() in ["nikita", "mavrin"]:
        return "T · " + ("СУЙТОН" if f.roster_name() == "nikita" else "КЭТ!") + (" ГОТОВО" if auxiliary_cd == 0 else " %.1f" % (auxiliary_cd / 60.0))
    return ""

func digest() -> Array:
    return [ai_clock, auxiliary_cd, water_frames, cheese_used, cheese_mode, cheese_remaining, cheese_recovery, cheese_pose, assist_variant, hold_frames, hold_source.team if is_instance_valid(hold_source) else -1, hold_counter_button, hold_counter_used, counter_frames, shave_frames, bald, one_punch_ready, punch_flash, one_punch_victory, hero.digest()]
