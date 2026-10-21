class_name FighterAbilities
extends RefCounted

# All timers are deterministic 60 Hz frames and pause between rounds.
const ENERGY_DURATION := 360
const PROTEIN_DURATION := 420
const RAGE_DURATION := 360
const FREEZE_DURATION := 54
const COOLDOWNS_R := [600, 720, 180]
const COOLDOWNS_N := [420, 660, 480]
const EFFECT = preload("res://fx/ability_effect.gd")
var fighter: Fighter
var yusup: YusupAbilities
var rinat: RinatAbilities
var expansion: ExpansionAbilities
var conversation_source: Fighter
var cooldowns: Array[int] = [0, 0, 0]
var energy_frames := 0
var protein_frames := 0
var rage_frames := 0
var freeze_frames := 0
var cast_frames := 0
var cast_slot := -1
var pose_frames := 0
var pose_kind := ""
var effect_name := ""
var flash_frames := 0
var _ai_timer := 90
var maris_frames := 0
var fish_frames := 0
var fat_frames := 0
var slow_frames := 0
var slow_strength := 0.0
var talking_frames := 0
var flying := false
var burn_frames := 0
var burn_clock := 0
var burn_power := 1.0
var stun_frames := 0
var teleport_frames := 0
var phone_frames := 0
var phone_roll := -1
var gesture_variant := 0
var away_frames := 0
var shrink_frames := 0
const NEW_EFFECT = preload("res://fx/newcomer_effect.gd")
const ROSTER_EFFECT = preload("res://fx/roster_effect.gd")

func _init(owner_fighter: Fighter) -> void:
    fighter = owner_fighter
    yusup = YusupAbilities.new(owner_fighter)
    rinat = RinatAbilities.new(owner_fighter)
    expansion = ExpansionAbilities.new(owner_fighter)

func is_rafael() -> bool:
    return fighter.roster_name() == "rafael"

func size_multiplier() -> float:
    return (0.78 if fighter.roster_name() == "bigboss" else 1.0) * (0.65 if shrink_frames > 0 else 1.0) * (1.4 if protein_frames > 0 else (1.15 if maris_frames > 0 else 1.0))

func width_multiplier() -> float:
    return 1.65 if fat_frames > 0 else (1.2 if maris_frames > 0 else 1.0)

func damage_multiplier() -> float:
    return (1.25 if rinat.master_frames > 0 else 1.0) * (0.6 if shrink_frames > 0 else 1.0) * (1.6 if protein_frames > 0 else 1.0) * (1.5 if rage_frames > 0 else 1.0) * (1.25 if maris_frames > 0 else 1.0)

func attack_speed_multiplier() -> float:
    return (1.45 if energy_frames > 0 else 1.0) * (1.15 if protein_frames > 0 else 1.0) * (1.25 if rage_frames > 0 else 1.0) * (1.5 if maris_frames > 0 else 1.0) * (1.1 if fish_frames > 0 else 1.0)

func speed_multiplier() -> float:
    return (1.65 if energy_frames > 0 else 1.0) * (1.15 if protein_frames > 0 else 1.0) * (1.1 if fish_frames > 0 else 1.0) * (1.25 if rage_frames > 0 else 1.0) * (0.5 if fat_frames > 0 else 1.0) * (1.8 if maris_frames > 0 else 1.0) * (1.0-slow_strength if slow_frames > 0 else 1.0)

func tick() -> void:
    expansion.tick()
    yusup.tick()
    rinat.tick()
    _tick_phone()
    _tick_teleport()
    if stun_frames > 0:
        stun_frames -= 1
        fighter.vel = Vector2.ZERO
    if burn_frames > 0:
        burn_frames -= 1
        burn_clock += 1
        if burn_clock%30 == 0 and not fighter.is_invulnerable():
            fighter.health = maxi(0,fighter.health-int(round(5*burn_power)))
    shrink_frames = maxi(0,shrink_frames-1)
    if away_frames > 0:
        away_frames -= 1
        fighter.visible = away_frames == 0
        fighter.vel = Vector2.ZERO
    for i in 3:
        cooldowns[i] = maxi(0, cooldowns[i] - 1)
    maris_frames = maxi(0,maris_frames-1)
    fish_frames = maxi(0,fish_frames-1)
    fat_frames = maxi(0,fat_frames-1)
    slow_frames = maxi(0,slow_frames-1)
    if slow_frames == 0:
        slow_strength = 0.0
    if talking_frames > 0:
        talking_frames -= 1
        if talking_frames % 14 == 0:
            _spawn("word")
    energy_frames = maxi(0, energy_frames - 1)
    protein_frames = maxi(0, protein_frames - 1)
    rage_frames = maxi(0, rage_frames - 1)
    pose_frames = maxi(0, pose_frames - 1)
    flash_frames = maxi(0, flash_frames - 1)
    if freeze_frames > 0:
        freeze_frames -= 1
        fighter.vel = Vector2.ZERO
        if freeze_frames == 0:
            fighter.hitstun_frames = 0
            fighter.state_machine.force_state("Idle" if fighter.on_ground else "Jump")
    if cast_frames > 0:
        cast_frames -= 1
        if cast_frames == 0:
            if fighter.roster_name() == "vladislav":
                fish_frames = 180
            elif cast_slot == 0:
                energy_frames = ENERGY_DURATION
            else:
                protein_frames = PROTEIN_DURATION
            flash_frames = 25
            cast_slot = -1
    _apply_speed()
    if fighter.roster_name() == "mavrin" and fighter.input_source is HumanInput and freeze_frames == 0:
        if _action_pressed(fighter.input_source.player_prefix,"fly"):
            toggle_flight()
    if locked():
        return
    if fighter.input_source is HumanInput:
        var prefix: String = fighter.input_source.player_prefix
        for slot in 3:
            if _action_pressed(prefix,"special"+str(slot+1)):
                activate(slot)
    elif fighter.input_source is AIInput:
        _ai_timer -= 1
        if _ai_timer <= 0:
            _ai_timer = 90 if fighter.input_source.difficulty == "hard" else 155
            var distance: float = absf(fighter.position.x - fighter.opponent.position.x)
            var slot := 0
            if fighter.roster_name() in ["vladislav","mavrin","ramis","ilgiz","bigboss","azat","polina","yusup","rinat"]:
                var available: Array[int] = []
                for i in 3:
                    if cooldowns[i] == 0:
                        available.append(i)
                slot = available.pick_random() if not available.is_empty() else 0
            elif not is_rafael():
                slot = 1 if rage_frames == 0 and cooldowns[1] == 0 else (2 if distance < 150.0 and cooldowns[2] == 0 else 0)
            else:
                slot = 0 if energy_frames == 0 and cooldowns[0] == 0 else (1 if protein_frames == 0 and cooldowns[1] == 0 else 2)
            activate(slot)

func _apply_speed() -> void:
    var base := Characters.stats(fighter.character_id)
    var multiplier := speed_multiplier()
    fighter.walk_fwd_speed = base["walk_fwd_speed"] * multiplier
    fighter.walk_back_speed = base["walk_back_speed"] * multiplier
    fighter.dash_fwd_speed = base["dash_fwd_speed"] * multiplier
    fighter.dash_back_speed = base["dash_back_speed"] * multiplier

func locked() -> bool:
    return expansion.locked() or rinat.locked() or conversation_locked() or stun_frames > 0 or away_frames > 0 or freeze_frames > 0 or cast_frames > 0 or pose_frames > 0 or talking_frames > 0

func conversation_locked() -> bool:
    return yusup.story_frames > 0 or (is_instance_valid(conversation_source) and conversation_source.abilities.yusup.story_frames > 0)

func activate(slot: int) -> bool:
    if expansion.cheese_mode or yusup.swim_frames > 0:
        return false
    if fighter.roster_name() == "yusup" and (not is_instance_valid(fighter.opponent) or fighter.opponent.health <= 0):
        return false
    if fighter.landing_lag_frames > 0 or slot < 0 or slot > 2 or cooldowns[slot] > 0 or locked() or fighter.frozen or (not fighter.on_ground and not (flying and fighter.roster_name() == "mavrin")):
        return false
    var state := fighter.state_machine.current_state
    if state == null or not str(state.name) in ["Idle", "Walk", "Crouch", "Jump"]:
        return false
    cooldowns[slot] = Roster.COOLDOWNS[fighter.roster_name()][slot]
    fighter._update_facing()
    fighter.vel = Vector2.ZERO
    fighter.current_move = null
    fighter.state_machine.force_state("Idle")
    if fighter.roster_name() == "rinat":
        rinat.activate(slot)
    elif fighter.roster_name() == "yusup":
        yusup.activate(slot)
    elif fighter.roster_name() == "polina":
        pose_kind = ["swim_teleport","rain_prayer","random_gesture"][slot]
        pose_frames = [50,80,45][slot]
        effect_name = ["НЫРОК В ПРОСТРАНСТВО","СИГАРЕТНЫЙ ДОЖДЬ","СЛУЧАЙНЫЙ ЖЕСТ"][slot]
        if slot == 0:
            teleport_frames = 48
        else:
            gesture_variant = randi_range(0,2)
            var effect := Node2D.new()
            effect.set_script(preload("res://fx/polina_effect.gd"))
            effect.kind = "rain" if slot == 1 else "gesture"
            effect.attacker = fighter
            effect.target = fighter.opponent
            effect.variant = gesture_variant
            fighter.get_parent().add_child(effect)
    elif fighter.roster_name() == "azat":
        pose_kind = ["whine","complain","plead"][slot]
        pose_frames = [65,80,95][slot]
        effect_name = ["НУ ПОЧЕМУ Я?","Я НЕ БУДУ!","ВСЁ НЕ ТАК!"][slot]
        # Entirely cosmetic: no damage, status changes, summons or projectiles.
    elif fighter.roster_name() == "ilgiz":
        match slot:
            0:
                pose_kind = "dogs"
                pose_frames = 28
                effect_name = "СОБАКИ, КО МНЕ!"
                for i in 3:
                    _spawn_new("dog",i)
            1:
                away_frames = 360
                fighter.visible = false
                effect_name = "ВЫШЕЛ НА 6 СЕКУНД"
            2:
                pose_kind = "negative"
                pose_frames = 32
                effect_name = "НУ ТАКОЕ..."
                _spawn_new("negative")
    elif fighter.roster_name() == "bigboss":
        pose_kind = ["pistol","rifle","crowd"][slot]
        pose_frames = [24,54,45][slot]
        effect_name = ["ПИСТОЛЕТ","АВТОМАТ","ТИК ТОК ДЕСАНТ"][slot]
        if slot < 2:
            for i in (1 if slot == 0 else 6):
                _spawn_new("bullet" if slot == 0 else "rifle_bullet",i)
        else:
            for i in 5:
                _spawn_new("schoolkid",i)
    elif fighter.roster_name() == "ramis":
        match slot:
            0:
                maris_frames = 360
                pose_kind = "maris"
                pose_frames = 18
                effect_name = "МАРИС"
            1:
                pose_kind = "sunbeam"
                pose_frames = 40
                effect_name = "СОЛНЕЧНЫЙ РИКОШЕТ"
                _spawn("sunbeam")
            2:
                pose_kind = "critters"
                pose_frames = 30
                effect_name = "КРАСНЫЙ ДЕСАНТ"
                for i in 4:
                    _spawn("critter",i)
    elif fighter.roster_name() == "vladislav":
        match slot:
            0:
                pose_kind = "burgers"
                pose_frames = 28
                effect_name = "БУРГЕРНАЯ ВОЛНА"
                for i in 5:
                    _spawn("burger",i)
            1:
                pose_kind = "fish"
                cast_slot = 1
                cast_frames = 30
                effect_name = "КРАСНУЮ РЫБУ"
            2:
                fat_frames = 480
                pose_kind = "fat"
                pose_frames = 18
                effect_name = "МАССА"
    elif fighter.roster_name() == "mavrin":
        match slot:
            0:
                pose_kind = "talk"
                talking_frames = 112
                effect_name = "СЛОВЕСНЫЙ ПОТОК"
            1:
                pose_kind = "splitkick"
                effect_name = "ШПАГАТ"
                var move := MoveData.new()
                move.move_name = "SplitKick"
                move.damage = 95
                move.startup = 8
                move.active = 6
                move.recovery = 22
                move.hitbox_offset = Vector2(40,-65)
                move.hitbox_size = Vector2(85,100)
                move.pushback = 250
                fighter.start_move(move)
                fighter.state_machine.transition_to("Attack")
            2:
                pose_kind = "phone"
                pose_frames = 48
                effect_name = "АЛЛО, САЛАХОВ?"
                phone_roll = randi_range(0,9)
                phone_frames = 24
    elif is_rafael() and slot < 2:
        cast_frames = 36
        cast_slot = slot
        pose_kind = "energy" if slot == 0 else "protein"
        effect_name = "ЭНЕРГЕТИК" if slot == 0 else "ПРОТЕИН"
    elif is_rafael():
        pose_kind = "mouth"
        pose_frames = 24
        effect_name = "ЗВУКОВАЯ ВОЛНА"
        _spawn("wave")
    elif slot == 0:
        pose_kind = "trap"
        pose_frames = 20
        effect_name = "ЗЕЛЁНАЯ ЛОВУШКА"
        _spawn("trap")
    elif slot == 1:
        rage_frames = RAGE_DURATION
        pose_kind = "rage"
        pose_frames = 20
        flash_frames = 30
        effect_name = "БЕРСЕРК"
    else:
        pose_kind = "blackflame"
        pose_frames = 36
        effect_name = "ЧЁРНОЕ ПЛАМЯ"
        var flame := Node2D.new()
        flame.set_script(preload("res://fx/black_flame.gd"))
        flame.attacker = fighter
        flame.target = fighter.opponent
        fighter.get_parent().add_child(flame)
    var id := fighter.roster_name()
    var sound := "buff" if slot == 1 else "swing_heavy"
    if id == "polina":
        sound = ["vanish","summon","trap"][slot]
    elif id == "ilgiz" and slot == 1:
        sound = "vanish"
    elif id == "nikita" and slot == 0:
        sound = "trap"
    elif id == "mavrin" and slot == 2:
        sound = "phone"
    elif id == "ramis" and slot == 1:
        sound = "beam"
    elif id in ["rafael","vladislav"] and slot < 2:
        sound = "item"
    elif (id == "ilgiz" and slot == 0) or slot == 2:
        sound = "summon"
    if id == "azat" or (id == "yusup" and slot == 0):
        return true
    if id != "bigboss" or slot == 2:
        fighter.emit_sound(sound)
    _apply_speed()
    return true

func _spawn_new(kind: String, variant: int = 0) -> void:
    var effect := Node2D.new()
    effect.set_script(NEW_EFFECT)
    effect.kind = kind
    effect.variant = variant
    effect.attacker = fighter
    effect.target = fighter.opponent
    effect.direction = fighter.facing()
    fighter.get_parent().add_child(effect)

func shrink() -> void:
    if not fighter.is_invulnerable():
        shrink_frames = 360

func _spawn(kind: String, variant: int = 0) -> void:
    var effect := Node2D.new()
    effect.set_script(ROSTER_EFFECT if kind in ["word","burger","sunbeam","critter"] else EFFECT)
    if kind in ["word","burger","sunbeam","critter"]:
        effect.variant = variant
    effect.kind = kind
    effect.attacker = fighter
    effect.target = fighter.opponent
    effect.direction = fighter.facing()
    fighter.get_parent().add_child(effect)

func interrupt_cast() -> void:
    expansion.interrupt()
    yusup.interrupt()
    rinat.interrupt()
    phone_frames = 0
    stun_frames = 0
    if teleport_frames > 0:
        teleport_frames = 0
        fighter.visible = true
    cast_frames = 0
    cast_slot = -1
    pose_frames = 0
    talking_frames = 0
    flying = false

func freeze() -> void:
    if fighter.is_invulnerable():
        return
    interrupt_cast()
    freeze_frames = FREEZE_DURATION
    fighter.vel = Vector2.ZERO
    fighter.current_move = null
    fighter.state_machine.force_state("Idle")

func reset() -> void:
    expansion.reset()
    yusup.reset()
    rinat.reset()
    conversation_source = null
    phone_frames = 0
    phone_roll = -1
    stun_frames = 0
    teleport_frames = 0
    gesture_variant = 0
    burn_frames = 0
    burn_clock = 0
    burn_power = 1.0
    away_frames = 0
    shrink_frames = 0
    fighter.visible = true
    maris_frames = 0
    fish_frames = 0
    fat_frames = 0
    slow_frames = 0
    slow_strength = 0.0
    talking_frames = 0
    flying = false
    cooldowns = [0, 0, 0]
    energy_frames = 0
    protein_frames = 0
    rage_frames = 0
    freeze_frames = 0
    cast_frames = 0
    cast_slot = -1
    pose_frames = 0
    pose_kind = ""
    flash_frames = 0
    _ai_timer = 90
    _apply_speed()

func status_text() -> String:
    if yusup.story_frames > 0:
        return yusup.speech()
    if rinat.bound_frames > 0:
        return "В ЦЕПЯХ %.1f" % (rinat.bound_frames / 60.0)
    if rinat.drink_frames > 0:
        return "ЭЛИКСИР…"
    if stun_frames > 0:
        return "В СТУПОРЕ %.1f" % (stun_frames/60.0)
    if freeze_frames > 0:
        return "В ЛОВУШКЕ %.1f" % (freeze_frames / 60.0)
    if cast_frames > 0:
        return "ПЬЁТ " + effect_name
    var states: Array[String] = []
    var extra_status := expansion.status()
    if not extra_status.is_empty():
        states.append(extra_status)
    if rinat.master_frames > 0:
        states.append("МАСТЕР +25%% · %.1f" % (rinat.master_frames / 60.0))
    if fighter.rhythm.depleted_frames > 0:
        states.append("А ЗАБЕЙ · ВЫНОСЛИВОСТЬ 0 · %.1f" % (fighter.rhythm.depleted_frames / 60.0))
    if yusup.swim_frames > 0:
        states.append("ПЛАВУНЕЦ %.1f" % (yusup.swim_frames / 60.0))
    if yusup.heat_frames > 0:
        states.append("МНЕ ХОЛОДНО! %.1f" % (yusup.heat_frames / 60.0))
    if burn_frames > 0:
        states.append("ГОРИТ %.1f" % (burn_frames/60.0))
    if away_frames > 0:
        states.append("ВНЕ АРЕНЫ %.1f" % (away_frames/60.0))
    if shrink_frames > 0:
        states.append("МАЛЕНЬКИЙ / СЛАБЫЙ %.1f" % (shrink_frames/60.0))
    if pose_frames > 0 and fighter.roster_name() in ["ilgiz","bigboss","azat","polina","yusup","rinat"]:
        states.append(effect_name)
    if maris_frames > 0:
        states.append("МАРИС %.1f" % (maris_frames/60.0))
    if fish_frames > 0:
        states.append("НЕУЯЗВИМ %.1f" % (fish_frames/60.0))
    if fat_frames > 0:
        states.append("МАССА %.1f" % (fat_frames/60.0))
    if slow_frames > 0:
        states.append("МЕДЛЕННЕЕ %d%%" % int(slow_strength*100))
    if talking_frames > 0:
        states.append("ГОВОРИТ")
    if flying:
        states.append("ПОЛЁТ")
    if pose_frames > 0 and pose_kind == "phone":
        states.append("АЛЛО, САЛАХОВ?")
    if energy_frames > 0:
        states.append("СКОРОСТЬ %.1f" % (energy_frames / 60.0))
    if protein_frames > 0:
        states.append("РОСТ / УРОН %.1f" % (protein_frames / 60.0))
    if rage_frames > 0:
        states.append("БЕРСЕРК %.1f" % (rage_frames / 60.0))
    return " · ".join(states)

func cooldown_text() -> String:
    var labels := ["Q", "E", "R"] if fighter.name != "Player2" else ["P", "[", "]"]
    var items: Array[String] = []
    for i in 3:
        items.append(labels[i] + (" ГОТОВО" if cooldowns[i] == 0 else " %.1f" % (cooldowns[i] / 60.0)))
    return "   ".join(items)

func add_slow() -> void:
    if fighter.is_invulnerable():
        return
    slow_strength = minf(slow_strength+0.12,0.72)
    slow_frames = 150
    _apply_speed()

func toggle_flight() -> void:
    if fighter.roster_name() != "mavrin" or fighter.frozen or freeze_frames > 0 or cast_frames > 0:
        return
    var state := fighter.state_machine.current_state
    if state != null and str(state.name) in ["Hitstun","Knockdown","Blockstun","Throw","Attack"]:
        return
    flying = not flying
    if flying:
        fighter.position.y = minf(fighter.position.y,150.0)
        fighter.on_ground = false
        fighter.state_machine.force_state("Jump")
    else:
        fighter.vel.y = 0
        fighter.state_machine.force_state("Jump")

func process_flight(delta: float) -> bool:
    if not flying:
        return false
    fighter.on_ground = false
    fighter._update_facing()
    if fighter.state_machine.current_state.name == "Attack":
        fighter.state_machine.physics_update(delta)
    elif fighter.try_start_attack("j"):
        fighter.state_machine.transition_to("Attack")
    var direction := -1.0 if fighter.input.up else (1.0 if fighter.input.down else 0.0)
    fighter.vel = Vector2(fighter.input.horizontal()*fighter.walk_fwd_speed,direction*120.0)
    fighter.position += fighter.vel*delta
    fighter.position.x = clampf(fighter.position.x,fighter.wall_left,fighter.wall_right)
    fighter.position.y = clampf(fighter.position.y,75.0,179.0)
    return true

func ignite(duration: int, power: float = 1.0) -> void:
    if fighter.is_invulnerable():
        return
    if burn_frames == 0:
        burn_clock = 0
        var flame := Node2D.new()
        flame.set_script(preload("res://fx/burn_visual.gd"))
        flame.fighter = fighter
        fighter.get_parent().add_child(flame)
    burn_frames = maxi(burn_frames,duration)
    burn_power = power

func stun(duration: int) -> void:
    if fighter.is_invulnerable() or stun_frames > 0:
        return
    interrupt_cast()
    stun_frames = duration
    fighter.vel = Vector2.ZERO
    fighter.current_move = null
    fighter.state_machine.force_state("Idle" if fighter.on_ground else "Jump")
    var stars := Node2D.new()
    stars.set_script(preload("res://fx/stun_visual.gd"))
    stars.fighter = fighter
    fighter.get_parent().add_child(stars)

func _tick_teleport() -> void:
    if teleport_frames == 0:
        return
    teleport_frames -= 1
    if not is_instance_valid(fighter.opponent):
        interrupt_cast()
        return
    if teleport_frames == 32:
        fighter.visible = false
    elif teleport_frames == 24:
        var target := fighter.opponent
        var side := 1 if target.position.x >= fighter.position.x else -1
        # Cross to the far side. At the wall, move the pair inward so neither clips.
        var desired := target.position.x+side*46
        if desired > fighter.wall_right:
            target.position.x = fighter.wall_right-46
        elif desired < fighter.wall_left:
            target.position.x = fighter.wall_left+46
        fighter.position.x = clampf(target.position.x+side*46,fighter.wall_left,fighter.wall_right)
        fighter.position.y = fighter.ground_y
        fighter.on_ground = true
        fighter.visible = true
        fighter._update_facing()
        fighter.emit_sound("swing_heavy")
    elif teleport_frames == 20:
        var target := fighter.opponent
        var reach := Rect2(fighter.position+Vector2(fighter.facing()*42-36,-96),Vector2(72,88))
        if not target.is_invulnerable() and reach.intersects(target.hurtbox_rect()):
            var move := MoveData.new()
            move.damage = int(round(105*damage_multiplier()))
            move.pushback = 140
            move.hitstun = 18
            if target.is_blocking(move):
                target.receive_block(move,fighter.facing())
            else:
                target.receive_hit(move,fighter.facing())
            fighter.get_parent()._on_hit(target)

func _action_pressed(prefix: String, action: String) -> bool:
    return NetSession.action_just_pressed(prefix,action) if NetSession.enabled else Input.is_action_just_pressed(prefix+"_"+action)

static func phone_succeeds(roll: int) -> bool:
    return roll == 0

func _tick_phone() -> void:
    if phone_frames == 0:
        return
    phone_frames -= 1
    if phone_frames > 0:
        return
    if phone_succeeds(phone_roll) and is_instance_valid(fighter.opponent):
        effect_name = "САЛАХОВ НА СВЯЗИ!"
        var assist := SalahovAssist.new()
        assist.attacker = fighter
        assist.target = fighter.opponent
        fighter.get_parent().add_child(assist)
    else:
        effect_name = "НЕ ОТВЕЧАЕТ..."
