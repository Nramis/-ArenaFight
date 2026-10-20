extends Node2D

var f: Fighter
var banks: Dictionary = {}
var regions: Dictionary = {}
var clock := 0.0
var distance := 0.0
var previous_x := 0.0
var previous_pose := 0
var pose := 0
var transition := 1.0

func _ready() -> void:
    f = get_parent().get_parent()
    previous_x = f.position.x
    var paths := {"base": "res://assets/rinat/rinat-base.png", "master": "res://assets/rinat/rinat-master.png"}
    if f.skin_id == "scorpion":
        paths = {"base": "res://assets/rinat/rinat-scorpion.png", "master": "res://assets/rinat/rinat-scorpion-master.png"}
    elif f.roster_name() == "vladislav":
        paths = {"base": "res://assets/skins/vlad-paquito.png"}
    var all_regions: Dictionary = {}
    if FileAccess.file_exists("res://assets/rinat/regions.json"):
        all_regions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/rinat/regions.json"))
    for bank in paths:
        if ResourceLoader.exists(paths[bank]):
            banks[bank] = load(paths[bank])
            regions[bank] = all_regions.get(str(paths[bank]).get_file(), {})

func _process(delta: float) -> void:
    if f.abilities == null or f.state_machine.current_state == null:
        return
    var dx := f.position.x - previous_x
    previous_x = f.position.x
    if not f.frozen and not f.abilities.conversation_locked() and f.hitstop_frames == 0:
        clock += delta
        if absf(dx) < 20:
            distance += absf(dx)
        transition = minf(1.0, transition + delta * 24)
    var next_pose := _pose()
    if next_pose != pose:
        previous_pose = pose
        pose = next_pose
        transition = 0
    queue_redraw()

func _pose() -> int:
    var r := f.abilities.rinat
    var state := str(f.state_machine.current_state.name)
    if f.health <= 0 or state in ["Knockdown", "Thrown"]:
        return 22
    if state == "Hitstun":
        return 21
    if state == "Blockstun":
        return 6 if f.input.down else 20
    if state == "Attack" and f.current_move != null:
        var move := f.current_move
        var frame := f.state_machine.current_state.state_frame
        if move.move_name == "RinatUppercut" or move.move_name == "Shoryuken":
            return 17 if frame < move.startup else (18 if frame < move.startup+move.active else 19)
        if frame < move.startup:
            return 10 if not move.move_name.to_lower().ends_with("k") else 7
        if frame >= move.startup + move.active + move.recovery * 0.6:
            return 10
        if move.move_name.to_lower().ends_with("k") or move.move_name == "Tatsu":
            return 15 if move.damage >= 70 else 14
        if move.move_name.begins_with("cr."):
            return 16
        return 13 if move.damage >= 80 else (12 if move.damage >= 45 else 11)
    if r.drink_frames > 0:
        return 27 if r.drink_frames > 10 else 28
    if r.chain_frames > 0:
        return 24 if r.chain_frames > RinatAbilities.CHAIN_FLIGHT else 25
    if f.abilities.pose_frames > 0:
        match f.abilities.pose_kind:
            "rinat_chain": return 26
            "rinat_vape": return 29 if r.smoke_windup > 0 else 30
            "burgers": return 25
            "fish": return 27
            "fat": return 31
    if r.tear_frames > 0:
        return 24 + mini(2,int((36-r.tear_frames)/12))
    if r.chant_frames > 0:
        return 27 + int(clock*6)%2 if r.shirt_torn else 31
    if state == "Crouch":
        return 5
    if state in ["Jump", "JumpStartup"]:
        return 7 if f.vel.y < -180 else (8 if f.vel.y < 180 else 9)
    if state in ["Walk", "Dash"]:
        return [2,3,4,3][int(distance/9)%4]
    return int(clock*2)%2

func _draw() -> void:
    if f == null or f.abilities == null:
        return
    var a := f.abilities
    var r := a.rinat
    var bank := "master" if r.shirt_torn and r.master_frames > 0 and banks.has("master") else "base"
    if not banks.has(bank) or not regions.has(bank) or regions[bank].is_empty():
        return
    var growth := a.size_multiplier()
    var width := a.width_multiplier()
    var wobble := sin(clock*4.2)*0.055 if r.master_frames > 0 and not a.locked() else 0.0
    var elasticity := sin(clock*6.5)*0.025 if r.master_frames > 0 else 0.0
    var tint := Color.WHITE
    if str(f.state_machine.current_state.name) == "Hitstun":
        tint = Color(1,0.7,0.6)
    if a.freeze_frames > 0:
        tint = Color(0.4,1,0.5)
    if f.invuln_frames > 0:
        tint.a = 0.8
    draw_set_transform(Vector2(0,maxf(0,f.ground_y-f.position.y)),0,Vector2(1,0.22))
    draw_circle(Vector2.ZERO,24*growth*width,Color(0,0,0,0.28))
    draw_set_transform(Vector2(sin(clock*4)*1.5 if r.master_frames > 0 else 0,0),wobble*f.facing(),Vector2(f.facing()*growth*width*(1+elasticity),growth*(1-elasticity)))
    _frame(bank,pose,tint)
    if a.fish_frames > 0:
        draw_arc(Vector2(0,-53),54,0,TAU,36,Color(1,0.75,0.35,0.65),1.5)
    draw_set_transform(Vector2.ZERO)

func _frame(bank: String, index: int, tint: Color) -> void:
    var data: Dictionary = regions[bank]
    var frame: Dictionary = data.frames[clampi(index,0,data.frames.size()-1)]
    var rect: Array = frame.rect
    var anchor: Array = frame.anchor
    var unit := 112.0 / float(data.height)
    if frame.has("polygon"):
        var points := PackedVector2Array()
        var uv := PackedVector2Array()
        for point in frame.polygon:
            var p := Vector2(point[0],point[1])
            points.append((p-Vector2(anchor[0],anchor[1]))*unit)
            uv.append(p/Vector2(banks[bank].get_size()))
        draw_colored_polygon(points,tint,uv,banks[bank])
        return
    var source := Rect2(rect[0],rect[1],rect[2],rect[3])
    var destination := Rect2(Vector2(float(rect[0])-float(anchor[0]),float(rect[1])-float(anchor[1]))*unit,source.size*unit)
    draw_texture_rect_region(banks[bank],destination,source,tint)
