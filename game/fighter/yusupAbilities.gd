class_name YusupAbilities
extends RefCounted

const INTRO_FRAMES := 120
const OUTRO_FRAMES := 90
const STORY_DURATION := INTRO_FRAMES + OUTRO_FRAMES
const EXHAUST_DURATION := 120
const HEAT_DURATION := 180
const SWIM_DURATION := 300
const SWIM_INTERVAL := 18
var fighter: Fighter
var story_frames := 0
var remote_frames := 0
var heat_frames := 0
var swim_frames := 0
var swim_hit_timer := 0
var story_target: Fighter

func _init(owner_fighter: Fighter) -> void:
    fighter = owner_fighter

func activate(slot: int) -> void:
    var ability := fighter.abilities
    ability.pose_kind = ["forget", "remote", "swimmer"][slot]
    ability.effect_name = ["А ЗАБЕЙ", "МНЕ ХОЛОДНО!", "ПЛАВУНЕЦ"][slot]
    match slot:
        0:
            story_frames = STORY_DURATION
            story_target = fighter.opponent
            story_target.abilities.conversation_source = fighter
            fighter.vel = Vector2.ZERO
            story_target.vel = Vector2.ZERO
            fighter.emit_sound("yusupStory")
        1:
            ability.pose_frames = 36
            remote_frames = 24
        2:
            swim_frames = SWIM_DURATION
            swim_hit_timer = 0

func tick_story() -> void:
    if story_frames <= 0:
        return
    story_frames -= 1
    if story_frames == OUTRO_FRAMES:
        fighter.emit_sound("yusupForget")
    if story_frames == 0:
        if is_instance_valid(story_target):
            story_target.rhythm.deplete(EXHAUST_DURATION)
        _release_story()

func speech() -> String:
    return "там короче..." if story_frames > OUTRO_FRAMES else "а забей"

func tick() -> void:
    heat_frames = maxi(0, heat_frames - 1)
    if remote_frames > 0:
        remote_frames -= 1
        if remote_frames == 0:
            heat_frames = HEAT_DURATION
            fighter.opponent.abilities.ignite(HEAT_DURATION, 3.0)
            var filter := CanvasLayer.new()
            filter.set_script(preload("res://fx/yusupHeat.gd"))
            filter.fighter = fighter
            fighter.get_parent().add_child(filter)
    if swim_frames > 0:
        swim_hit_timer = maxi(0, swim_hit_timer - 1)
        _swim_contact()
        swim_frames -= 1

func _swim_contact() -> void:
    var target := fighter.opponent
    if swim_hit_timer > 0 or not is_instance_valid(target) or target.is_invulnerable():
        return
    var state := str(fighter.state_machine.current_state.name)
    if state in ["Hitstun", "Blockstun", "Knockdown", "Thrown", "Throw"] or fighter.hitstop_frames > 0:
        return
    var reach := fighter.hurtbox_rect().grow(15.0)
    if not reach.intersects(target.hurtbox_rect()):
        return
    swim_hit_timer = SWIM_INTERVAL
    var move := MoveData.new()
    move.move_name = "YusupWindmill"
    move.damage = int(round(26 * fighter.abilities.damage_multiplier()))
    move.hitstun = 8
    move.blockstun = 6
    move.pushback = 20
    if target.is_blocking(move):
        target.receive_block(move, fighter.facing())
    else:
        target.receive_hit(move, fighter.facing())
    fighter.get_parent()._on_hit(target)

func interrupt() -> void:
    story_frames = 0
    remote_frames = 0
    _release_story()

func _release_story() -> void:
    if is_instance_valid(story_target) and story_target.abilities.conversation_source == fighter:
        story_target.abilities.conversation_source = null
    story_target = null

func reset() -> void:
    interrupt()
    heat_frames = 0
    swim_frames = 0
    swim_hit_timer = 0
