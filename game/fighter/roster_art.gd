extends Node2D

const VLAD = preload("res://assets/vladislav.png")
const MAVRIN = preload("res://assets/mavrin.png")
const NEWCOMERS = preload("res://assets/newcomers.png")
const RAMIS = preload("res://assets/ramis.png")
var t := 0.0

func _process(delta: float) -> void:
    var owner_fighter: Fighter = get_parent()
    if owner_fighter.abilities != null and owner_fighter.abilities.conversation_locked():
        return
    t += delta
    queue_redraw()

func _draw() -> void:
    var f: Fighter = get_parent()
    var a := f.abilities
    var state := str(f.state_machine.current_state.name)
    var tint := Color.WHITE
    if a.freeze_frames > 0:
        tint = Color(0.3,1,0.4)
    elif a.fish_frames > 0:
        tint = Color(1,0.85,0.55)
    elif state == "Hitstun":
        tint = Color(1,0.6,0.6)
    draw_set_transform(Vector2(0,maxf(0,180-f.position.y)),0,Vector2(1,0.23))
    draw_circle(Vector2.ZERO,25,Color(0,0,0,0.3))
    var lean := -0.1 if state == "Hitstun" else (-1.2 if state == "Knockdown" else 0.0)
    draw_set_transform(Vector2.ZERO,lean*f.facing(),Vector2(float(f.facing())*a.size_multiplier(),a.size_multiplier()))
    if f.roster_name() in ["ilgiz","bigboss"]:
        _draw_newcomer(f,a,state,tint)
    elif f.roster_name() == "vladislav":
        var pose := 0
        var row := 0
        if state == "Walk" or state == "Dash":
            pose = 1
        elif state == "Crouch" or state == "Blockstun":
            pose = 4
        elif state == "Attack":
            pose = 3 if f.current_move != null and f.current_move.move_name.to_lower().ends_with("k") else 2
        if a.pose_frames > 0 and a.pose_kind == "burgers":
            row = 1
            pose = 0
        elif a.cast_frames > 0 and a.pose_kind == "fish":
            row = 1
            pose = 1
        elif a.fat_frames > 0 and pose in [0,1,2,3]:
            row = 1
            pose += 2
        _draw_vlad(pose,row,tint)
        if a.fat_frames > 0 and row == 0:
            # Crouching body stays visibly broad too.
            draw_arc(Vector2(0,-47),24,0,TAU,24,Color(0.6,0.8,0.9,0.2),4)
        if a.fish_frames > 0:
            draw_arc(Vector2(0,-50),53,0,TAU,40,Color(1,0.65,0.25,0.75),1.5)
    elif f.roster_name() == "ramis":
        _draw_ramis(f,a,state,tint)
    else:
        _draw_mavrin(f,a,state,tint)
    draw_set_transform(Vector2.ZERO)

func _draw_vlad(pose: int, row: int, tint: Color) -> void:
    var outlines = [
        [Vector2(0,0),Vector2(258,0),Vector2(258,500),Vector2(0,500)],
        [Vector2(258,0),Vector2(510,0),Vector2(510,500),Vector2(258,500)],
        [Vector2(510,0),Vector2(800,0),Vector2(800,500),Vector2(510,500)],
        [Vector2(800,0),Vector2(1105,0),Vector2(1105,205),Vector2(945,205),Vector2(945,500),Vector2(800,500)],
        [Vector2(1030,200),Vector2(1235,200),Vector2(1235,500),Vector2(1030,500)],
        [Vector2(1250,0),Vector2(1536,0),Vector2(1536,500),Vector2(1235,500),Vector2(1235,375),Vector2(1250,330)]
    ]
    var anchors = [128,377,638,875,1136,1383]
    var baseline := 475.0
    if row == 1:
        outlines = [
            [Vector2(0,512),Vector2(295,512),Vector2(295,650),Vector2(270,650),Vector2(270,1024),Vector2(0,1024)],
            [Vector2(300,512),Vector2(495,512),Vector2(495,1024),Vector2(270,1024),Vector2(270,660),Vector2(300,660)],
            [Vector2(496,512),Vector2(750,512),Vector2(750,1024),Vector2(496,1024)],
            [Vector2(730,512),Vector2(958,512),Vector2(958,1024),Vector2(730,1024)],
            [Vector2(958,512),Vector2(1255,512),Vector2(1255,1024),Vector2(958,1024)],
            [Vector2(1255,512),Vector2(1536,512),Vector2(1536,1024),Vector2(1255,1024)]
        ]
        anchors = [128,380,625,843,1105,1388]
        baseline = 963.0
    var points := PackedVector2Array()
    var uv := PackedVector2Array()
    for point: Vector2 in outlines[pose]:
        points.append(Vector2((point.x-float(anchors[pose]))*0.24,(point.y-baseline)*0.24))
        uv.append(point/Vector2(VLAD.get_size()))
    draw_colored_polygon(points,tint,uv,VLAD)

func _draw_mavrin(f: Fighter, ability: FighterAbilities, state: String, tint: Color) -> void:
    var pose := 7 if ability.flying else 0
    if state in ["Walk","Dash"]:
        pose = 1
    elif state == "Attack":
        pose = 3 if f.current_move != null and (f.current_move.move_name == "SplitKick" or f.current_move.move_name.to_lower().ends_with("k")) else 2
    elif state in ["Crouch","Blockstun"]:
        pose = 4
    if ability.talking_frames > 0:
        pose = 5
    elif ability.pose_frames > 0 and ability.pose_kind == "phone":
        pose = 6
    if ability.freeze_frames > 0:
        pose = 0
    var regions = [Rect2(0,0,385,500),Rect2(385,0,382,500),Rect2(767,0,421,500),Rect2(1188,0,348,500),Rect2(0,512,384,500),Rect2(384,500,384,510),Rect2(768,500,360,510),Rect2(1128,500,408,510)]
    var anchors = [192.0,577.0,951.0,1285.0,192.0,576.0,947.0,1330.0]
    var baseline := 476.0 if pose < 4 else 975.0
    var source: Rect2 = regions[pose]
    var bob := -sin(t*4)*1.5 if ability.flying else 0.0
    var dest := Rect2(Vector2((source.position.x-anchors[pose])*0.24,(source.position.y-baseline)*0.24+bob),source.size*0.24)
    draw_texture_rect_region(MAVRIN,dest,source,tint)
    if ability.flying:
        for i in range(3):
            draw_line(Vector2(-12+i*12,8),Vector2(-12+i*12,18+sin(t*8+i)*4),Color(0.65,0.7,1,0.5),1.5)
    if ability.talking_frames > 0:
        draw_arc(Vector2(15,-82),9,-PI/2,PI/2,12,Color("cebfff"),1.3)

func _draw_ramis(f: Fighter, ability: FighterAbilities, state: String, tint: Color) -> void:
    var pose := 0
    if ability.maris_frames > 0:
        pose = 4 if int(t*12)%2 == 0 else 5
    elif state in ["Walk","Dash"]:
        pose = 1
    elif state == "Attack":
        pose = 3 if f.current_move != null and f.current_move.move_name.to_lower().ends_with("k") else 2
    if ability.pose_frames > 0 and ability.pose_kind == "sunbeam":
        pose = 6
    elif ability.pose_frames > 0 and ability.pose_kind == "critters":
        pose = 7
    var regions = [Rect2(0,0,384,512),Rect2(384,0,384,512),Rect2(768,0,420,512),Rect2(1188,0,348,512),Rect2(0,512,426,512),Rect2(426,512,382,512),Rect2(808,512,344,512),Rect2(1152,512,384,512)]
    var anchors = [192.0,576.0,960.0,1300.0,200.0,610.0,950.0,1350.0]
    var source: Rect2 = regions[pose]
    var baseline := 493.0 if pose < 4 else 976.0
    var scale_value := ability.size_multiplier()
    var width := ability.width_multiplier() if ability.maris_frames > 0 else 1.0
    var vertical := 0.75 if state == "Crouch" and ability.maris_frames == 0 else 1.0
    draw_set_transform(Vector2.ZERO,0,Vector2(f.facing()*scale_value*width,scale_value*vertical))
    draw_texture_rect_region(RAMIS,Rect2(Vector2((source.position.x-anchors[pose])*0.22,(source.position.y-baseline)*0.22),source.size*0.22),source,tint)

func _draw_newcomer(f: Fighter, ability: FighterAbilities, state: String, tint: Color) -> void:
    var boss := f.roster_name() == "bigboss"
    var pose := 0
    if boss:
        if ability.pose_frames > 0:
            pose = {"pistol":1,"rifle":2,"crowd":3}.get(ability.pose_kind,0)
    else:
        if state in ["Walk","Dash"]:
            pose = 1
        elif state == "Attack":
            pose = 2
        if ability.pose_frames > 0:
            pose = 3
    var cell := Vector2(NEWCOMERS.get_width()/4.0,NEWCOMERS.get_height()/2.0)
    var source := Rect2(Vector2(pose*cell.x,cell.y if boss else 0),cell)
    var bob := -absf(sin(t*14))*2 if state in ["Walk","Dash"] else 0.0
    var squat := 0.65 if state in ["Crouch","Blockstun"] else 1.0
    draw_set_transform(Vector2(0,bob),-0.12 if state == "Hitstun" else (-1.2 if state == "Knockdown" else 0.0),Vector2(f.facing()*ability.size_multiplier(),ability.size_multiplier()*squat))
    draw_texture_rect_region(NEWCOMERS,Rect2(-cell.x*0.12,-cell.y*0.24+5,cell.x*0.24,cell.y*0.24),source,tint)
    if boss and ability.pose_frames > 0 and ability.pose_kind in ["pistol","rifle"] and int(t*30)%3 == 0:
        draw_circle(Vector2(42,-68),4,Color("ffe4a2"))
