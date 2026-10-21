class_name RamisShaveArt
extends Node2D

const TEXTURE = preload("res://assets/grapples/ramis-shave.png")
const METADATA := "res://assets/grapples/ramis-shave.json"
const VICTORY_TEXTURE = preload("res://assets/grapples/ramis-victory.png")
const VICTORY_METADATA := "res://assets/grapples/ramis-victory.json"
var victory_regions: Dictionary = {}
var f: Fighter
var regions: Dictionary = {}
var clock := 0.0
var original_material: Material

static func handles(fighter: Fighter) -> bool:
    return fighter != null and fighter.abilities != null and fighter.roster_name() == "ramis" and (fighter.abilities.expansion.shave_frames > 0 or fighter.abilities.expansion.bald)

func _ready() -> void:
    f = get_parent().get_parent()
    regions = JSON.parse_string(FileAccess.get_file_as_string(METADATA))
    victory_regions = JSON.parse_string(FileAccess.get_file_as_string(VICTORY_METADATA))

func _process(delta: float) -> void:
    if original_material == null and material != null:
        original_material = material
    material = null if f.abilities.expansion.bald or (f.abilities.expansion.shave_frames > 0 and f.abilities.expansion.shave_frames <= 48) else original_material
    if not f.frozen and f.hitstop_frames == 0:
        clock += delta
    queue_redraw()

func _draw() -> void:
    if not handles(f) or regions.is_empty():
        return
    var a := f.abilities.expansion
    if a.hero.active():
        return
    if a.shave_frames > 0 and a.shave_frames <= 48:
        RamisHeroAtlas.draw_pose(self, "transform", clampi((48 - a.shave_frames) / 3, 0, 15), Vector2.ZERO, f.facing())
        return
    if a.bald:
        _draw_costume()
        return
    if a.one_punch_victory:
        var match_state: MatchState = f.get_parent().match_state
        var age := 0 if match_state.phase == MatchState.FIGHT else (120 if match_state.phase == MatchState.MATCH_END else match_state.phase_frame)
        draw_victory(self, victory_regions, age, Vector2.ZERO, f.facing())
        return
    var state := str(f.state_machine.current_state.name)
    var index := 12 + int(fmod(clock * 2, 2))
    var lean := 0.0
    var offset := Vector2.ZERO
    if a.shave_frames > 0:
        index = clampi((ExpansionAbilities.SHAVE_DURATION - a.shave_frames) / 10, 0, 11)
    elif state == "Attack" and f.current_move != null:
        var frame := f.state_machine.current_state.state_frame
        if frame < f.current_move.startup:
            index = 20
        elif frame < f.current_move.startup + f.current_move.active:
            index = 22
        else:
            index = 21 if frame < f.current_move.startup + f.current_move.active + 4 else 23
    elif state in ["Walk", "Dash"]:
        index = 14 + int(fmod(clock * (13 if state == "Dash" else 7), 2))
    elif state in ["Jump", "JumpStartup"]:
        index = 17
    elif state == "Crouch":
        index = 16
    elif state == "Blockstun":
        index = 19
    elif state in ["Hitstun", "Knockdown", "Thrown"] or f.health <= 0:
        index = 18
        if state in ["Knockdown", "Thrown"] or f.health <= 0:
            lean = -1.35
            offset = Vector2(-12, -6)
    if f.abilities.maris_frames > 0 and a.shave_frames == 0:
        index = 16
    var growth := f.abilities.size_multiplier()
    var frame: Dictionary = regions.frames[index]
    var anchor: Array = frame.anchor
    var reference_height := 280.0 if index < 12 else (220.0 if index < 18 else 217.0)
    var unit := (68.0 if f.abilities.maris_frames > 0 else 112.0) / reference_height
    draw_set_transform(Vector2.ZERO, 0, Vector2(1, .22))
    draw_circle(Vector2.ZERO, 23 * growth, Color(0, 0, 0, .26))
    draw_set_transform(Vector2.ZERO)
    if a.one_punch_ready and f.health > 0:
        draw_arc(Vector2(0, -52), 56 + sin(clock * 7) * 2, -.85, .85, 24, Color(1, .85, .35, .45), 1.5)
        draw_arc(Vector2(0, -52), 56 + sin(clock * 7) * 2, PI-.85, PI+.85, 24, Color(1, .85, .35, .45), 1.5)
    draw_set_transform(offset, lean * f.facing(), Vector2(f.facing() * growth, growth))
    var tint := Color(1, .65, .6) if state == "Hitstun" else Color.WHITE
    if f.abilities.freeze_frames > 0:
        tint = Color(.4, 1, .6)
    for polygon in frame.polygons:
        var points := PackedVector2Array()
        var uvs := PackedVector2Array()
        for pair in polygon:
            var point := Vector2(pair[0], pair[1])
            points.append((point - Vector2(anchor[0], anchor[1])) * unit)
            uvs.append(point / Vector2(TEXTURE.get_size()))
        draw_colored_polygon(points, tint, uvs, TEXTURE)
    draw_set_transform(Vector2.ZERO)
    if a.punch_flash > 0:
        for i in 5:
            draw_line(Vector2(f.facing() * (25 + i * 7), -58 - i * 3), Vector2(f.facing() * (55 + i * 8), -58 - i * 3), Color(1, .9, .6, a.punch_flash / 30.0), 2)

static func draw_victory(canvas: Node2D, bank: Dictionary, age: int, origin: Vector2, direction: int) -> void:
    if bank.is_empty():
        return
    var index := clampi(age / 5, 0, 11)
    var frame: Dictionary = bank.frames[index]
    var anchor: Array = frame.anchor
    var unit: float = 112.0 / [266.0, 272.0, 287.0][index / 4]
    canvas.draw_set_transform(origin, 0, Vector2(direction, 1))
    for polygon in frame.polygons:
        var points := PackedVector2Array()
        var uvs := PackedVector2Array()
        for pair in polygon:
            var point := Vector2(pair[0], pair[1])
            points.append((point - Vector2(anchor[0], anchor[1])) * unit)
            uvs.append(point / Vector2(VICTORY_TEXTURE.get_size()))
        canvas.draw_colored_polygon(points, Color.WHITE, uvs, VICTORY_TEXTURE)
    canvas.draw_set_transform(Vector2.ZERO)

func _draw_costume() -> void:
    var a := f.abilities.expansion
    var state := str(f.state_machine.current_state.name)
    if a.one_punch_victory and a.hero.crater_active:
        RamisHeroAtlas.draw_pose(self, "victory", 15, Vector2.ZERO, 1)
        return
    var index := int(fmod(clock * 2.4, 4))
    if state in ["Walk", "Dash"]:
        index = 8 + int(fmod(clock * 10, 2)) if state == "Dash" else 4 + int(fmod(clock * 8, 4))
    elif state in ["Jump", "JumpStartup"]:
        index = 10
    elif state == "Crouch":
        index = 11
    elif state == "Blockstun":
        index = 12
    elif state == "Hitstun":
        index = 13
    elif state in ["Knockdown", "Thrown"] or f.health <= 0:
        index = 14
    elif state == "Attack":
        index = 15
    var tint := Color(1,.65,.6) if state == "Hitstun" else Color.WHITE
    if f.abilities.freeze_frames > 0:
        tint = Color(.4,1,.6)
    if a.one_punch_ready and f.health > 0:
        draw_set_transform(Vector2(0,-2),0,Vector2(1,.23))
        draw_arc(Vector2.ZERO,34+sin(clock*6)*2,0,TAU,48,Color(1,.85,.35,.7),2)
        draw_set_transform(Vector2.ZERO)
    RamisHeroAtlas.draw_pose(self,"motion",index,Vector2.ZERO,f.facing(),f.abilities.size_multiplier(),0,tint)
