extends Node2D
const ATLAS = preload("res://assets/polina-specials.png")
const BASELINES = [480, 477, 469, 472, 473, 472, 473, 474]
var f: Fighter
var clock := 0.0
func _ready() -> void:
    f = get_parent()
func _process(delta: float) -> void:
    if not f.frozen and not f.abilities.conversation_locked() and f.hitstop_frames == 0:
        clock += delta
    queue_redraw()
func _draw() -> void:
    if f == null or f.abilities == null:
        return
    var a := f.abilities
    var pose := 0
    if a.pose_kind == "swim_teleport":
        pose = 0 if a.teleport_frames > 38 else (1 if a.teleport_frames > 24 else 7)
    elif a.pose_kind == "rain_prayer":
        pose = 2 if a.pose_frames > 52 else 3
    elif a.pose_kind == "random_gesture":
        pose = 4+a.gesture_variant
    var cell := Vector2(ATLAS.get_width()/4.0,ATLAS.get_height()/2.0)
    var growth := a.size_multiplier()
    draw_set_transform(Vector2(0,0),0,Vector2(1,0.22))
    draw_circle(Vector2.ZERO,22*growth,Color(0,0,0,0.25))
    draw_set_transform(Vector2(0,sin(clock*5)*0.4),0,Vector2(f.facing()*growth,growth))
    var tint := Color(0.3,1,0.4) if a.freeze_frames > 0 else Color.WHITE
    var source: Rect2 = PolinaAtlas.REGIONS["specials"][pose]
    var origin := Vector2(pose%4,int(pose/4))*cell
    draw_texture_rect_region(ATLAS,Rect2((source.position-origin-Vector2(cell.x/2,BASELINES[pose]))*0.235,source.size*0.235),source,tint)
    draw_set_transform(Vector2.ZERO)
