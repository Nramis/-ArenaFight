class_name LocomotionArt
extends Node2D

const BANKS = {
    "walk-a":preload("res://assets/locomotion/walk-a.png"),
    "walk-b":preload("res://assets/locomotion/walk-b.png"),
    "walk-c":preload("res://assets/locomotion/walk-c.png"),
    "maris":preload("res://assets/locomotion/maris.png")
}
var f: Fighter
var distance := 0.0
var previous_x := 0.0
var breathing := 0.0

static func handles(fighter: Fighter) -> bool:
    if fighter == null or fighter.abilities == null or fighter.state_machine.current_state == null or fighter.health <= 0:
        return false
    if fighter.roster_name() == "rinat" or fighter.skin_id != "default":
        return false
    var a := fighter.abilities
    var state := str(fighter.state_machine.current_state.name)
    if state in ["Hitstun","Knockdown","Throw"] or a.cast_frames > 0 or a.pose_frames > 0 or a.talking_frames > 0 or a.flying or a.fat_frames > 0:
        return false
    if a.maris_frames > 0:
        return true
    return state in ["Walk","Dash"] and LocomotionAtlas.DATA.has(fighter.roster_name())

func _ready() -> void:
    f = get_parent()
    previous_x = f.position.x

func _process(delta: float) -> void:
    var dx := f.position.x-previous_x
    previous_x = f.position.x
    if not f.frozen and not f.abilities.conversation_locked() and f.hitstop_frames == 0 and f.abilities.freeze_frames == 0 and f.abilities.stun_frames == 0:
        if absf(dx) < 20:
            distance += dx*f.facing()
        breathing += delta
    queue_redraw()

func _draw() -> void:
    if not handles(f):
        return
    var maris := f.abilities.maris_frames > 0
    var data: Dictionary = LocomotionAtlas.DATA["maris" if maris else f.roster_name()]
    var frame := LocomotionAtlas.frame_at(distance)
    if maris and absf(f.vel.x) < 1:
        frame = 0 if sin(breathing*2.5) >= 0 else 4
    if maris and f.state_machine.current_state.name == "Attack":
        frame = posmod(f.state_machine.current_state.state_frame/3,8)
    var source: Rect2 = data.regions[frame]
    # One stable per-character scale; crop bounds never determine pose height.
    var height := 0.0
    for rect: Rect2 in data.regions:
        height = maxf(height,rect.size.y)
    var unit := (67.0 if maris else 110.0)/height
    var growth := f.abilities.size_multiplier()
    var tint := Color.WHITE
    if f.abilities.rage_frames > 0:
        tint = Color(1,0.38,0.32)
    if f.abilities.freeze_frames > 0:
        tint = Color(0.3,1,0.4)
    if f.abilities.shrink_frames > 0:
        tint = Color(0.8,0.75,1)
    if f.invuln_frames > 0:
        tint.a = 0.78
    draw_set_transform(Vector2(0,maxf(0,f.ground_y-f.position.y)),0,Vector2(1,0.22))
    draw_circle(Vector2.ZERO,(32 if maris else 23)*growth,Color(0,0,0,0.28))
    var bob := sin(breathing*3)*0.4 if maris and absf(f.vel.x) < 1 else 0.0
    draw_set_transform(Vector2(0,bob),0,Vector2(f.facing()*growth,growth))
    draw_texture_rect_region(BANKS[data.bank],Rect2(Vector2(-source.size.x/2,-source.size.y)*unit,source.size*unit),source,tint)
    draw_set_transform(Vector2.ZERO)
