extends Node
const ACTIONS := ["left","right","up","down","lp","mp","hp","lk","mk","hk","special1","special2","special3","fly"]
var enabled := false
var seat := 0
var run_id := ""
var buffer := LockstepBuffer.new()
var masks := [0,0]
var edges := [0,0]
var started := false
var arena: MatchManager
var _callback: JavaScriptObject
var _waiting_since := 0
var _label: Label
var _hashes: Dictionary = {}
var _remote_hashes: Dictionary = {}
var _last_hash_frame := -1
var _stopped := false
func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = -1000
    process_physics_priority = -1000
    if not OS.has_feature("web"):
        set_physics_process(false)
        return
    enabled = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('net') === '1'"))
    if not enabled:
        set_physics_process(false)
        return
    seat = clampi(int(JavaScriptBridge.eval("Number(new URLSearchParams(location.search).get('seat') || '0')")),0,1)
    run_id = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('run') || ''"))
    seed(int(JavaScriptBridge.eval("Number(new URLSearchParams(location.search).get('seed') || '1')")))
    _callback = JavaScriptBridge.create_callback(_on_message)
    JavaScriptBridge.get_interface("window").addEventListener("message",_callback)
    GameConfig.p2_is_cpu = false
func begin(manager: MatchManager) -> void:
    arena = manager
    buffer.reset()
    started = false
    _waiting_since = Time.get_ticks_msec()
    get_tree().paused = true
    var layer := CanvasLayer.new()
    layer.layer = 40
    add_child(layer)
    _label = Label.new()
    _label.position = Vector2(56,84)
    _label.size = Vector2(272,46)
    _label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _label.add_theme_font_size_override("font_size",10)
    var box := StyleBoxFlat.new()
    box.bg_color = Color(0.02,0.04,0.08,0.94)
    _label.add_theme_stylebox_override("normal",box)
    _label.text = "СОПЕРНИК ЗАГРУЖАЕТСЯ..."
    layer.add_child(_label)
    _send({"type":"arena-network-loaded"})
func _on_message(args: Array) -> void:
    if args.is_empty() or not enabled:
        return
    var event = args[0]
    if str(event.origin) != str(JavaScriptBridge.eval("window.location.origin")):
        return
    var data = event.data
    if typeof(data) != TYPE_OBJECT or str(data.run) != run_id:
        return
    match str(data.type):
        "arena-network-go":
            if not started and not _stopped:
                buffer.reset(int(data.delay))
                started = true
                _waiting_since = 0
        "arena-network-input":
            buffer.receive(int(data.frame),int(data.mask))
        "arena-network-checksum":
            var f := int(data.frame)
            if f >= buffer.frame-240 and f <= buffer.frame+240:
                _remote_hashes[f] = str(data.hash)
                _compare(f)
        "arena-network-stop":
            stop("Связь прервана. Вернись в лобби.")
func _physics_process(_delta: float) -> void:
    if not enabled or arena == null or _stopped:
        return
    if not started:
        if Time.get_ticks_msec()-_waiting_since > 120000:
            stop("Соперник не загрузился. Вернись в лобби.")
        return
    var mask := 0
    for i in ACTIONS.size():
        if Input.is_action_pressed("p1_"+ACTIONS[i]):
            mask |= 1 << i
    var future := buffer.queue_local(mask)
    if future >= 0:
        _send({"type":"arena-network-input","frame":future,"mask":mask})
    if not buffer.ready():
        get_tree().paused = true
        if _waiting_since == 0:
            _waiting_since = Time.get_ticks_msec()
        _label.visible = Time.get_ticks_msec()-_waiting_since > 120
        _label.text = "ЖДЁМ СОПЕРНИКА..."
        if Time.get_ticks_msec()-_waiting_since > 20000:
            stop("Нет данных от соперника. Вернись в лобби.")
        return
    if buffer.frame > 0 and buffer.frame%120 == 0 and _last_hash_frame != buffer.frame:
        _last_hash_frame = buffer.frame
        var digest := state_digest()
        _hashes[buffer.frame] = digest
        _send({"type":"arena-network-checksum","frame":buffer.frame,"hash":digest})
        _compare(buffer.frame)
        _hashes.erase(buffer.frame-240)
        _remote_hashes.erase(buffer.frame-240)
        if _stopped:
            return
    var pair := buffer.advance()
    var next := pair if seat == 0 else [pair[1],pair[0]]
    for i in 2:
        edges[i] = int(next[i]) & ~int(masks[i])
        masks[i] = int(next[i])
    _waiting_since = 0
    _label.visible = false
    get_tree().paused = false
func input_for(prefix: String) -> InputFrame:
    var f := InputFrame.new()
    for i in 10:
        f.set(ACTIONS[i],(int(masks[1 if prefix == "p2" else 0]) & (1 << i)) != 0)
    return f
func action_just_pressed(prefix: String, action: String) -> bool:
    var bit := ACTIONS.find(action)
    return bit >= 0 and (int(edges[1 if prefix == "p2" else 0]) & (1 << bit)) != 0
func state_digest() -> String:
    var data: Array = [arena.match_state.phase,arena.match_state.phase_frame,arena.match_state.timer,arena.match_state.p1_rounds,arena.match_state.p2_rounds]
    for f: Fighter in [arena.p1,arena.p2]:
        data.append([f.health,roundi(f.position.x*1000),roundi(f.position.y*1000),roundi(f.vel.x*1000),roundi(f.vel.y*1000),str(f.state_machine.current_state.name),f.state_machine.current_state.state_frame,f.abilities.cooldowns,f.abilities.freeze_frames,f.abilities.stun_frames,f.abilities.burn_frames,f.abilities.pose_frames,f.invuln_frames,f.knockdown_frames,f.hitstun_frames,f.combo_count,f.combo_damage,f.rhythm.stamina,f.abilities.phone_frames,f.abilities.phone_roll])
        data.append([f.rhythm.depleted_frames, f.abilities.yusup.story_frames, f.abilities.yusup.remote_frames, f.abilities.yusup.heat_frames, f.abilities.yusup.swim_frames, f.abilities.yusup.swim_hit_timer, f.abilities.conversation_source.team if is_instance_valid(f.abilities.conversation_source) else -1])
        data.append(f.abilities.ruslan.digest())
    for effect in arena.get_tree().get_nodes_in_group("ability_effect"):
        if effect is SalahovAssist:
            data.append(["salahov",effect.attacker.team,effect.age,effect.strikes,roundi(effect.position.x*1000)])
    return JSON.stringify(data).sha256_text()
func _compare(f: int) -> void:
    if _hashes.has(f) and _remote_hashes.has(f) and _hashes[f] != _remote_hashes[f]:
        stop("Состояния боя разошлись. Вернитесь в лобби.")
func stop(message: String) -> void:
    if _stopped:
        return
    _stopped = true
    get_tree().paused = true
    if _label != null:
        _label.text = message
        _label.visible = true
    _send({"type":"arena-network-error","message":message})
func request_lobby() -> void:
    get_tree().paused = true
    _send({"type":"arena-network-menu"})
func _send(data: Dictionary) -> void:
    data["run"] = run_id
    if OS.has_feature("web"):
        JavaScriptBridge.eval("window.parent.postMessage("+JSON.stringify(data)+",window.location.origin)")
