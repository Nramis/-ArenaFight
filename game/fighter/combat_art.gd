extends Node2D

var texture: Texture2D
var transition_texture: Texture2D
var posture_texture: Texture2D
var crouch_blend := 0.0
var legacy: Node2D
var clock := 0.0
var gait := 0.0
var walk_blend := 0.0
var f: Fighter

func _ready() -> void:
    f = get_parent()
    if f.roster_name() == "rinat" or (f.roster_name() == "vladislav" and f.skin_id == "paquito"):
        var custom := Node2D.new()
        custom.set_script(preload("res://fighter/rinat_art.gd"))
        add_child(custom)
        return
    var locomotion := LocomotionArt.new()
    f.call_deferred("add_child",locomotion)
    if f.roster_name() == "yusup":
        var yusup := Node2D.new()
        yusup.set_script(preload("res://fighter/yusupArt.gd"))
        add_child(yusup)
        return
    if f.roster_name() == "azat":
        var azat := Node2D.new()
        azat.set_script(preload("res://fighter/azat_art.gd"))
        add_child(azat)
        return
    var texture_path := "res://assets/motion/"+f.roster_name()+".png"
    if ResourceLoader.exists(texture_path):
        texture = load(texture_path)
    var transition_path := "res://assets/transitions/"+f.roster_name()+".png"
    if ResourceLoader.exists(transition_path):
        transition_texture = load(transition_path)
    var posture_path := "res://assets/postures/"+f.roster_name()+".png"
    if ResourceLoader.exists(posture_path):
        posture_texture = load(posture_path)
    legacy = Node2D.new()
    legacy.visible = false
    legacy.set_script(preload("res://fighter/polina_special_art.gd") if f.roster_name() == "polina" else preload("res://fighter/fighter_art.gd") if f.roster_name() in ["rafael","nikita"] else preload("res://fighter/roster_art.gd"))
    # Legacy special art expects Fighter as its direct parent.
    f.call_deferred("add_child",legacy)

func _exit_tree() -> void:
    if is_instance_valid(legacy) and not legacy.is_queued_for_deletion():
        legacy.queue_free()

func _process(delta: float) -> void:
    if f.abilities == null:
        return
    if not f.frozen and not f.abilities.conversation_locked() and f.hitstop_frames == 0 and f.abilities.freeze_frames == 0:
        clock += delta
        var state := str(f.state_machine.current_state.name)
        var crouching := state == "Crouch" or (state == "Blockstun" and f.input.down) or (state == "Attack" and f.current_move != null and f.current_move.move_name.begins_with("cr."))
        crouch_blend = move_toward(crouch_blend,1.0 if crouching else 0.0,delta*12)
        walk_blend = move_toward(walk_blend,1.0 if state in ["Walk","Dash"] else 0.0,delta*9)
        gait += absf(f.vel.x)*delta/27.0*(1.0 if f.vel.x*f.facing() >= 0 else -1.0)
    var a := f.abilities
    var special := texture == null or _uses_special_art()
    if is_instance_valid(legacy):
        legacy.visible = special and f.health > 0 and not LocomotionArt.handles(f)
    queue_redraw()

func _draw() -> void:
    if texture == null or f.abilities == null or f.state_machine.current_state == null:
        return
    var a := f.abilities
    _draw_aura(a)
    if LocomotionArt.handles(f):
        return
    if _uses_special_art():
        return
    var state := str(f.state_machine.current_state.name)
    var pose := 0
    var bob := sin(clock*3.5)*0.45
    var lean := 0.0
    var stretch := Vector2.ONE
    var offset := 0.0
    if state in ["Walk","Dash"]:
        pose = AnimationTimeline.walk_pose(gait,transition_texture != null)
        var step := sin(gait*PI)
        bob = -absf(step)*1.15*walk_blend
        stretch = Vector2(1.0+absf(step)*0.009,1.0-absf(step)*0.013)
        offset = sin(gait*TAU)*0.55*walk_blend
        lean = (0.025 if f.vel.x*f.facing()>0 else -0.02)*walk_blend+sin(gait*PI)*0.008
        if state == "Dash":
            lean = 0.14
    elif state in ["Jump","JumpStartup"]:
        pose = 5 if state == "Jump" else 7
        if state == "Jump":
            stretch = Vector2(1.0-clampf(-f.vel.y/660.0,0,1)*0.025,1.0+clampf(f.vel.y/660.0,-1,1)*0.04)
        lean = clampf(f.vel.x/1800.0,-0.12,0.12)*f.facing()
    elif state in ["Crouch","Blockstun"]:
        pose = 7 if state == "Crouch" or f.input.down else 0
        if pose == 7:
            stretch.y = 0.75
            if posture_texture != null and crouch_blend < 0.8:
                pose = 16
                stretch.y = 1.0
        bob = 0
    elif state in ["Hitstun","Knockdown"]:
        pose = 6
        lean = -0.08 if state == "Hitstun" else -1.4
        if state == "Knockdown" and transition_texture != null:
            if f.state_machine.current_state.state_frame < 6:
                lean = -f.state_machine.current_state.state_frame/8.0
            else:
                pose = AnimationTimeline.knockdown_pose(f.state_machine.current_state.state_frame,f.knockdown_frames)
                lean = 0
        bob = 0
    elif state == "Attack" and f.current_move != null:
        var move := f.current_move
        var frame := float(f.state_machine.current_state.state_frame)
        var kick := move.move_name.to_lower().ends_with("k") or move.move_name == "Tatsu"
        var heavy := move.damage >= 80
        var progress := clampf(frame/maxf(1,move.startup),0,1)
        if frame < move.startup:
            offset = -(6 if heavy else 3)*sin(progress*PI)
            stretch = Vector2(1.0+0.025*sin(progress*PI),1.0-0.025*sin(progress*PI))
            lean = -0.04*sin(progress*PI)
            pose = AnimationTimeline.attack_pose(frame,move.startup,move.active,move.recovery,kick,transition_texture != null)
        elif frame < move.startup+move.active:
            pose = 4 if kick else 3
            offset = 9 if heavy else 5
            lean = 0.075 if heavy else 0.04
            stretch = Vector2(1.045,0.975)
        else:
            var recovery := clampf((frame-move.startup-move.active)/maxf(move.recovery,1),0,1)
            pose = AnimationTimeline.attack_pose(frame,move.startup,move.active,move.recovery,kick,transition_texture != null)
            offset = (9 if heavy else 5)*(1-recovery)
            lean = -0.035*sin(recovery*PI) if heavy else 0.0
        if move.move_name.begins_with("cr."):
            if posture_texture != null:
                var contact := frame >= move.startup and frame < move.startup+move.active+move.recovery*0.4
                pose = (19 if move.move_name.to_lower().ends_with("hk") else 18) if kick and contact else (17 if contact else 16)
            else:
                stretch.y = 0.73
        if not f.on_ground:
            if posture_texture != null:
                pose = (22 if kick else 21) if frame >= move.startup else 20
            lean -= 0.12
        bob = 0
    if f.landing_frames > 4 and state != "Attack" and posture_texture != null:
        pose = 23
        stretch = Vector2.ONE
    elif state in ["Idle","Walk"] and crouch_blend > 0.15 and posture_texture != null:
        pose = 16
    if f.health <= 0 and transition_texture != null:
        pose = 14
        lean = 0
        stretch = Vector2.ONE
    if a.freeze_frames > 0 or a.stun_frames > 0:
        pose = 0
        bob = 0
        lean = 0
    if f.landing_frames > 0 and state != "Attack":
        var squash := sin(f.landing_frames/8.0*PI)*0.09
        stretch *= Vector2(1+squash,1-squash)
    var tint := Color.WHITE
    if a.rage_frames > 0:
        tint = Color(1,0.38,0.32)
    if a.shrink_frames > 0:
        tint = Color(0.8,0.75,1)
    if state == "Hitstun":
        tint = Color(1,0.6,0.55)
    if f.invuln_frames > 0 and state in ["Idle","Walk","Crouch"]:
        tint = Color(0.65,0.95,1,0.75+0.2*sin(clock*35))
    if f.hitstop_frames > 0 and state in ["Hitstun","Knockdown"]:
        tint = Color(1,0.9,0.8)
    if a.freeze_frames > 0:
        tint = Color(0.3,1,0.4)
    var growth := a.size_multiplier()
    draw_set_transform(Vector2(0,maxf(0,180-f.position.y)),0,Vector2(1,0.22))
    draw_circle(Vector2.ZERO,27*growth,Color(0,0,0,0.12))
    draw_circle(Vector2.ZERO,20*growth,Color(0,0,0,0.28))
    draw_set_transform(Vector2(offset*f.facing(),bob),lean*f.facing(),Vector2(f.facing()*growth*stretch.x,growth*stretch.y))
    var atlas: Texture2D = posture_texture if pose >= 16 else (transition_texture if pose >= 8 else texture)
    var index := pose%8
    var cell := Vector2(atlas.get_width()/4.0,atlas.get_height()/2.0)
    var row := int(index/4)
    var source := Rect2(Vector2((index%4)*cell.x,0 if row == 0 else 500),Vector2(cell.x,500 if row == 0 else 524))
    if pose == 5 and f.roster_name() != "polina":
        source = JumpAtlas.REGIONS[f.roster_name()]
    if f.roster_name() == "polina":
        var bank := "postures" if pose >= 16 else ("transitions" if pose >= 8 else "motion")
        source = PolinaAtlas.REGIONS[bank][index]
    # Uniform cells keep feet planted; jump pose itself has tucked legs.
    var scale_value := 0.235
    var baseline: float = PostureAtlas.BASELINES.get(f.roster_name(),[480,480,480,480,480,480,480,480])[index] if pose >= 16 else (MotionAtlas.BASELINES[f.roster_name()][index] if pose < 8 else TransitionAtlas.BASELINES.get(f.roster_name(),[480,480,480,480,480,480,480,480])[index])
    var anchor: float = MotionAtlas.ANCHORS[f.roster_name()][index] if pose < 8 else 192.0
    if pose == 5:
        anchor = source.get_center().x-cell.x
    if pose == 4 and f.roster_name() != "polina":
        # Extended kicks need a wider upper region, isolated from the next pose.
        var outline := PackedVector2Array([Vector2(0,512),Vector2(442,512),Vector2(442,748),Vector2(350,748),Vector2(350,1024),Vector2(0,1024)])
        var points := PackedVector2Array()
        var uv := PackedVector2Array()
        for point in outline:
            points.append(Vector2((point.x-anchor)*scale_value,(point.y-512-baseline)*scale_value))
            uv.append(point/Vector2(texture.get_size()))
        draw_colored_polygon(points,tint,uv,texture)
    elif pose == 22:
        var outline := PackedVector2Array([Vector2(768,500),Vector2(1228,500),Vector2(1228,800),Vector2(1152,800),Vector2(1152,1024),Vector2(736,1024),Vector2(736,800),Vector2(768,800)])
        if f.roster_name() == "polina":
            outline = PackedVector2Array([Vector2(782,524),Vector2(1247,524),Vector2(1247,684),Vector2(1180,684),Vector2(1180,872),Vector2(782,872)])
        var points := PackedVector2Array()
        var uv := PackedVector2Array()
        for point in outline:
            points.append(Vector2((point.x-960)*scale_value,(point.y-512-baseline)*scale_value))
            uv.append(point/Vector2(atlas.get_size()))
        draw_colored_polygon(points,tint,uv,atlas)
    elif pose == 14 and f.roster_name() != "polina":
        var right: float = TransitionAtlas.FALL_RIGHT[f.roster_name()]
        var outline := PackedVector2Array([Vector2(768,512),Vector2(1152,512),Vector2(1152,740),Vector2(right,740),Vector2(right,1024),Vector2(720,1024),Vector2(720,740),Vector2(768,740)])
        var points := PackedVector2Array()
        var uv := PackedVector2Array()
        for point in outline:
            points.append(Vector2((point.x-960)*scale_value,(point.y-512-baseline)*scale_value))
            uv.append(point/Vector2(atlas.get_size()))
        draw_colored_polygon(points,tint,uv,atlas)
    else:
        draw_texture_rect_region(atlas,Rect2(Vector2(source.position.x-(index%4)*cell.x-anchor,source.position.y-row*cell.y-baseline)*scale_value,source.size*scale_value),source,tint)
    if state == "Dash":
        for i in 3:
            draw_line(Vector2(-35-i*3,-30-i*16),Vector2(-50-i*4,-30-i*16),Color(0.7,0.9,1,0.35),1.4)
    if state == "Attack" and f.is_attack_active():
        var kick := f.current_move.move_name.to_lower().ends_with("k")
        var heavy := f.current_move.damage >= 80
        var color := Color(1,0.77,0.32,0.75) if heavy else Color(0.7,0.95,1,0.6)
        for i in (3 if heavy else 2):
            draw_arc(Vector2(13-i*3,-40 if kick else -72),24+i*4,-0.9,0.8,18,Color(color,color.a/(i+1)),2.2 if heavy else 1.3)
    draw_set_transform(Vector2.ZERO)

func _draw_aura(a: FighterAbilities) -> void:
    var color := Color(0,0,0,0)
    if a.energy_frames > 0:
        color = Color(0.4,0.85,1,0.5)
    elif a.protein_frames > 0 or a.maris_frames > 0:
        color = Color(1,0.75,0.3,0.5)
    elif a.rage_frames > 0:
        color = Color(1,0.25,0.2,0.5)
    elif a.shrink_frames > 0:
        color = Color(0.7,0.5,1,0.5)
    elif a.fish_frames > 0:
        color = Color(1,0.9,0.5,0.5)
    if color.a == 0:
        return
    var growth := a.size_multiplier()
    draw_set_transform(Vector2(0,-4),0,Vector2(growth,growth*0.3))
    draw_arc(Vector2.ZERO,31+sin(clock*6)*2,0,TAU,32,color,2)
    draw_set_transform(Vector2.ZERO)
    for i in 5:
        var point := Vector2(sin(clock*2+i*1.9)*28,-fmod(clock*27+i*19,90))*growth
        draw_circle(point,1.1,color)

func _uses_special_art() -> bool:
    var a := f.abilities
    var split_kick := f.state_machine.current_state != null and f.state_machine.current_state.name == "Attack" and f.current_move != null and f.current_move.move_name == "SplitKick"
    return f.health > 0 and (a.cast_frames > 0 or a.pose_frames > 0 or a.talking_frames > 0 or a.flying or a.fat_frames > 0 or a.maris_frames > 0 or split_kick)
