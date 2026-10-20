extends Node

## Config global entre escenas (autoload). El menú la escribe; el MatchManager la lee.

var p2_is_cpu: bool = false
var cpu_difficulty: String = "medium"
var roster_enabled := false
var p1_character := "rafael"
var p2_character := "nikita"
var p1_skin := "default"
var p2_skin := "default"
var stage_id := "rooftop"
var quick_start := false
var menu_open := false
var sound_enabled := true
var sound_volume := 0.8
var _audio_callback: JavaScriptObject
var show_boxes: bool = false   # cajas de golpe/daño visibles (F1 para alternar)

func set_mode(cpu: bool, difficulty: String) -> void:
    p2_is_cpu = cpu
    cpu_difficulty = difficulty

func _ready() -> void:
    if OS.has_feature("web"):
        stage_id = Stages.valid(str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('stage') || 'rooftop'")))
        quick_start = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('quickstart') === '1'"))
        sound_enabled = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('sound') || '1'")) != "0"
        sound_volume = clampf(float(JavaScriptBridge.eval("Number(new URLSearchParams(location.search).get('volume') || '0.8')")),0,1)
        _audio_callback = JavaScriptBridge.create_callback(_on_audio_message)
        JavaScriptBridge.get_interface("window").addEventListener("message",_audio_callback)
        var mode = JavaScriptBridge.eval("new URLSearchParams(location.search).get('mode') || 'cpu'")
        var difficulty = JavaScriptBridge.eval("new URLSearchParams(location.search).get('difficulty') || 'easy'")
        p2_is_cpu = str(mode) != "2p"
        cpu_difficulty = str(difficulty) if str(difficulty) in ["easy", "medium", "hard"] else "easy"

        roster_enabled = true
        p1_character = Roster.valid(str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('p1') || 'rafael'")))
        p2_character = Roster.valid(str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('p2') || 'nikita'")))
        p1_skin = Skins.valid(p1_character, str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('skin1') || 'default'")))
        p2_skin = Skins.valid(p2_character, str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('skin2') || 'default'")))

func set_audio(enabled: bool, volume: float = -1.0) -> void:
    sound_enabled = enabled
    if volume >= 0:
        sound_volume = clampf(volume,0,1)
    apply_audio()
    if OS.has_feature("web"):
        JavaScriptBridge.eval("window.parent.postMessage("+JSON.stringify({"type":"arena-audio-state","enabled":sound_enabled,"volume":sound_volume})+",window.location.origin)")

func apply_audio() -> void:
    var bus := AudioServer.get_bus_index("ArenaSFX")
    if bus >= 0:
        AudioServer.set_bus_mute(bus,not sound_enabled or sound_volume <= 0)
        AudioServer.set_bus_volume_db(bus,linear_to_db(maxf(sound_volume,0.001)))

func _on_audio_message(args: Array) -> void:
    if args.is_empty():
        return
    var event = args[0]
    if str(event.origin) != str(JavaScriptBridge.eval("window.location.origin")):
        return
    var data = event.data
    if typeof(data) != TYPE_OBJECT:
        return
    if str(data.type) == "arena-menu-state":
        if not NetSession.enabled:
            menu_open = bool(data.paused)
            get_tree().paused = menu_open
            if menu_open:
                _release_actions()
    elif str(data.type) == "arena-audio":
        set_audio(bool(data.enabled),float(data.volume))

func open_browser_selection(view: String = "menu") -> bool:
    if not OS.has_feature("web") or not bool(JavaScriptBridge.eval("window.parent !== window")):
        return false
    if not NetSession.enabled:
        menu_open = true
        get_tree().paused = true
    _release_actions()
    JavaScriptBridge.eval("window.parent.postMessage(" + JSON.stringify({"type": "arena-open-menu", "view": view}) + ",window.location.origin)")
    return true

func _release_actions() -> void:
    for action in InputMap.get_actions():
        Input.action_release(action)
