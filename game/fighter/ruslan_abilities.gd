class_name RuslanAbilities
extends RefCounted

const DARK_DURATION := 240
const DARK_WINDUP := 36
const PILAF_WINDUP := 30
const DICE_WINDUP := 54
const DICE_LOSS := 150
const RAIN_OFFSETS := [0, -22, 22, -44, 44, -11, 11, -33, 33, -55, 55, 0, -18, 18]
var fighter: Fighter
var pilaf_frames := 0
var dark_cast := 0
var dark_frames := 0
var dice_frames := 0
var dice_a := 0
var dice_b := 0
var dice_reveal := 0
var rain_frames := 0
var rain_spawned := 0
var rain_center := 192.0
var shots: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var coins: Array[Dictionary] = []
var sequence: Array[String] = []
var combo_paid := false
var last_heal := 0
var notice := ""
var notice_frames := 0
var combo_style := ""
var simulation_frame := 0

func _init(owner_fighter: Fighter) -> void:
    fighter = owner_fighter

func wealth_tier() -> int:
    var ratio := float(fighter.health) / maxf(1, fighter.max_health)
    return 0 if ratio > 0.66 else (1 if ratio > 0.33 else 2)

func activate(slot: int) -> void:
    fighter.abilities.pose_kind = ["pilaf", "blackout", "dice"][slot]
    fighter.abilities.pose_frames = [60, DARK_WINDUP, DICE_WINDUP][slot]
    fighter.abilities.effect_name = ["ПЛОВ НА ВЫНОС", "ЧЁРНЫЙ ДЕНЬ", "ВА-БАНК"][slot]
    match slot:
        0:
            pilaf_frames = PILAF_WINDUP
        1:
            dark_cast = DARK_WINDUP
        2:
            dice_frames = DICE_WINDUP
            # Exactly two gameplay RNG draws, never from rendering or audio.
            dice_a = randi_range(1, 6)
            dice_b = randi_range(1, 6)
            dice_reveal = 0

func tick() -> void:
    if fighter.roster_name() != "ruslan":
        return
    simulation_frame += 1
    notice_frames = maxi(0, notice_frames - 1)
    dice_reveal = maxi(0, dice_reveal - 1)
    dark_frames = maxi(0, dark_frames - 1)
    if dark_cast > 0:
        dark_cast -= 1
        if dark_cast == 0:
            dark_frames = DARK_DURATION
            _notice("ЧЁРНЫЙ ДЕНЬ · 4 СЕКУНДЫ")
    if pilaf_frames > 0:
        pilaf_frames -= 1
        if pilaf_frames == 0:
            for i in 3:
                shots.append({"x": fighter.position.x + fighter.facing() * 25, "y": fighter.position.y - 62.0, "vx": fighter.facing() * (235.0 + i * 28), "vy": -70.0 - i * 32, "age": -i * 6, "hit": false})
    if dice_frames > 0:
        dice_frames -= 1
        if dice_frames == 18:
            resolve_dice()
    _tick_projectiles()
    _tick_coins()

func resolve_dice() -> void:
    dice_reveal = 120
    if dice_a == dice_b:
        rain_frames = 168
        rain_spawned = 0
        rain_center = clampf(fighter.opponent.position.x, 45, 339)
        _notice("ДУБЛЬ %d:%d · ДЕНЕЖНЫЙ ДОЖДЬ!" % [dice_a, dice_b])
        fighter.emit_sound("summon")
    else:
        var loss := mini(fighter.health, DICE_LOSS)
        fighter.health -= loss
        took_damage(loss)
        _notice("%d:%d · СТАВКА СГОРЕЛА −%d" % [dice_a, dice_b, loss])
        fighter.emit_sound("counter")

func _tick_projectiles() -> void:
    var target := fighter.opponent
    if not is_instance_valid(target):
        return
    for shot in shots:
        if shot.hit:
            continue
        shot.age += 1
        if shot.age < 0:
            continue
        shot.x += shot.vx / 60.0
        shot.y += shot.vy / 60.0
        shot.vy += 155.0 / 60.0
        if not target.is_invulnerable() and Rect2(shot.x - 8, shot.y - 6, 16, 12).intersects(target.hurtbox_rect()):
            shot.hit = true
            _hit(target, 54, false, "RuslanPilaf")
        elif shot.y > 184 or shot.x < -20 or shot.x > 404 or shot.age > 130:
            shot.hit = true
    shots = shots.filter(func(item: Dictionary) -> bool: return not item.hit)
    if rain_frames > 0:
        if rain_spawned < RAIN_OFFSETS.size() and (168 - rain_frames) % 7 == 0:
            drops.append({"x": rain_center + RAIN_OFFSETS[rain_spawned], "y": -18.0, "age": 0, "hit": false})
            rain_spawned += 1
        rain_frames -= 1
    for drop in drops:
        drop.age += 1
        drop.y += 4.1
        if not target.is_invulnerable() and Rect2(drop.x - 7, drop.y - 9, 14, 18).intersects(target.hurtbox_rect()):
            drop.hit = true
            _hit(target, 80, true, "RuslanMoneyRain")
        elif drop.y > 188:
            drop.hit = true
    drops = drops.filter(func(item: Dictionary) -> bool: return not item.hit)

func _hit(target: Fighter, damage: int, overhead: bool, move_name: String) -> void:
    var move := MoveData.new()
    move.move_name = move_name
    move.damage = int(round(damage * fighter.abilities.damage_multiplier()))
    move.hitstun = 11
    move.blockstun = 7
    move.pushback = 24
    move.hits_overhead = overhead
    var direction := 1 if target.position.x >= fighter.position.x else -1
    if target.is_blocking(move):
        target.receive_block(move, direction)
    else:
        target.receive_hit(move, direction)
    fighter.get_parent()._on_hit(target)

func prepare_normal(move: MoveData) -> void:
    combo_style = ""
    if sequence.size() < 2 or not is_instance_valid(fighter.opponent) or fighter.opponent.combo_count < 2 or str(fighter.opponent.state_machine.current_state.name) != "Hitstun":
        return
    var button := move.move_name.to_lower().get_slice(".", 1)
    if button not in ["hp", "hk"]:
        return
    var last_two := sequence.slice(-2)
    if last_two[0].ends_with("p") and last_two[1].ends_with("p") and button == "hp":
        combo_style = "КОЛЛЕКТОР"
        move.damage = int(round(move.damage * 1.18))
        move.pushback += 35
    elif last_two[0].ends_with("k") and last_two[1].ends_with("k") and button == "hk":
        combo_style = "ПЕНАЛЬТИ"
        move.pushback += 90
        move.damage = int(round(move.damage * 1.12))
    else:
        combo_style = "РЕФИНАНСИРОВАНИЕ"
        move.hitstun += 5

func confirmed_hit(move: MoveData, actual_damage: int, hit_count: int, total_damage: int) -> void:
    # Only clean normals fund the passive. Rain, pilaf, throws and chip cannot.
    if move.is_special or move.move_name.to_lower().get_slice(".", 1) not in ["lp", "lk", "mp", "mk", "hp", "hk"]:
        sequence.clear()
        return
    if hit_count == 1:
        sequence.clear()
        combo_paid = false
    sequence.append(move.move_name.to_lower().get_slice(".", 1))
    if sequence.size() > 6:
        sequence.pop_front()
    if hit_count < 3 or sequence.size() < 3 or combo_paid or actual_damage <= 0:
        return
    combo_paid = true
    var amount := mini(90, int(round(total_damage * (0.32 if combo_style == "КОЛЛЕКТОР" else 0.24))))
    last_heal = mini(amount, fighter.max_health - fighter.health)
    fighter.health += last_heal
    _burst(fighter.opponent.position + Vector2(0, -65), 9, true)
    _notice((combo_style if combo_style != "" else "ВЗЫСКАНИЕ ДОЛГА") + " · +%d ₽ / HP" % last_heal)
    fighter.emit_sound("item")

func took_damage(amount: int) -> void:
    if fighter.roster_name() == "ruslan" and amount > 0:
        _burst(fighter.position + Vector2(0, -58), clampi(2 + amount / 20, 3, 9), false)

func _burst(origin: Vector2, count: int, toward_owner: bool) -> void:
    for i in count:
        coins.append({"x": origin.x, "y": origin.y, "vx": (-1.0 if i % 2 == 0 else 1.0) * (35.0 + i * 13), "vy": -90.0 - i * 13, "age": 0, "collect": toward_owner})
    while coins.size() > 45:
        coins.pop_front()

func _tick_coins() -> void:
    for coin in coins:
        coin.age += 1
        if coin.collect and coin.age > 12:
            coin.x = lerpf(coin.x, fighter.position.x, 0.16)
            coin.y = lerpf(coin.y, fighter.position.y - 65, 0.16)
        else:
            coin.x += coin.vx / 60.0
            coin.y += coin.vy / 60.0
            coin.vy += 350.0 / 60.0
            if coin.y > 177:
                coin.y = 177
                coin.vy = -absf(coin.vy) * 0.35
    coins = coins.filter(func(item: Dictionary) -> bool: return item.age < 54)

func _notice(message: String) -> void:
    notice = message
    notice_frames = 120

func interrupt() -> void:
    pilaf_frames = 0
    dark_cast = 0
    dice_frames = 0

func reset() -> void:
    interrupt()
    dark_frames = 0
    dice_a = 0
    dice_b = 0
    dice_reveal = 0
    rain_frames = 0
    rain_spawned = 0
    rain_center = 192
    shots.clear()
    drops.clear()
    coins.clear()
    sequence.clear()
    combo_paid = false
    last_heal = 0
    notice = ""
    notice_frames = 0
    combo_style = ""
    simulation_frame = 0

func digest() -> Array:
    return [pilaf_frames, dark_cast, dark_frames, dice_frames, dice_a, dice_b, dice_reveal, rain_frames, rain_spawned, snappedf(rain_center, 0.001), shots, drops, sequence, combo_paid, combo_style, simulation_frame]
