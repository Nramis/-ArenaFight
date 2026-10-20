extends Node2D

# This layer adds touch input; it never changes keyboard bindings.
const UI_FONT = preload("res://assets/fonts/Manrope.ttf")
const CENTER := Vector2(46,166)
const RADIUS := 29.0
const DIRECTIONS := ["p1_left","p1_right","p1_up","p1_down"]
const SPECIAL_NAMES = {
    "rafael":["ЭНЕРГИЯ","ПРОТЕИН","ВОЛНА"], "nikita":["СФЕРА","БЕРСЕРК","ПЛАМЯ"],
    "vladislav":["БУРГЕРЫ","РЫБА","МАССА"], "mavrin":["РЕЧЬ","ШПАГАТ","ЗВОНОК"],
    "ramis":["МАРИС","ЛУЧ","ДЕСАНТ"], "ilgiz":["СОБАКИ","УЙТИ","НЕГАТИВ"],
    "bigboss":["ПИСТОЛЕТ","АВТОМАТ","ТОЛПА"],
    "azat":["ПОЧЕМУ Я","НЕ БУДУ","ВСЁ НЕ ТАК"],
    "polina":["НЫРОК","ДОЖДЬ","ЖЕСТ"],
    "yusup":["А ЗАБЕЙ","ХОЛОДНО!","ПЛАВУНЕЦ"],
    "rinat":["ЦЕПЬ","МАСТЕР","ДЫМ"]
}
var enabled := false
var stick_finger := -1
var stick := Vector2.ZERO
var fingers: Dictionary = {}
var held: Dictionary = {}
var buttons: Array[Dictionary] = []
var fighter: Fighter

func _ready() -> void:
    if NetSession.enabled:
        process_mode = Node.PROCESS_MODE_ALWAYS
    enabled = DisplayServer.is_touchscreen_available()
    if OS.has_feature("web"):
        enabled = bool(JavaScriptBridge.eval("new URLSearchParams(location.search).get('touch') === '1'"))
    fighter = get_parent().get_parent().get_node("Player2" if NetSession.enabled and NetSession.seat == 1 else "Player1")
    for i in 3:
        buttons.append({"action":"p1_special"+str(i+1),"center":Vector2(280+i*33,111),"radius":15.0,"label":"","slot":i})
    var actions := ["lp","mp","hp","lk","mk","hk"]
    var labels := ["Р1","Р2","Р3","Н1","Н2","Н3"]
    for i in 6:
        buttons.append({"action":"p1_"+actions[i],"center":Vector2(280+(i%3)*33,148+int(i/3)*34),"radius":15.0,"label":("НЫТЬ "+str(i%3+1) if fighter.roster_name() == "azat" else labels[i]),"slot":-1})
    buttons.append({"action":"ui_cancel","center":Vector2(192,55),"radius":14.0,"label":"МЕНЮ","slot":-1})
    buttons.append({"action":"toggle_audio","center":Vector2(230,55),"radius":14.0,"label":"ЗВУК","slot":-1})
    buttons.append({"action":"p1_fly","center":Vector2(104,181),"radius":17.0,"label":"ПОЛЁТ","slot":-1})
    visible = enabled
    set_process(enabled)
    set_process_input(enabled)

func _process(_delta: float) -> void:
    var manager: MatchManager = get_parent().get_parent()
    visible = enabled and manager.match_state.phase == MatchState.FIGHT and not GameConfig.menu_open
    if not visible:
        release_all()
    queue_redraw()

func _input(event: InputEvent) -> void:
    if not enabled or (is_inside_tree() and not visible):
        return
    if event is InputEventScreenTouch:
        if not event.pressed or event.canceled:
            _release_finger(event.index)
        elif event.position.distance_to(CENTER) <= RADIUS+14 and stick_finger == -1:
            stick_finger = event.index
            _set_stick(event.position)
        else:
            for button in buttons:
                if button.action == "p1_fly" and fighter.roster_name() != "mavrin":
                    continue
                if Rect2(button.center-Vector2.ONE*button.radius,Vector2.ONE*button.radius*2).has_point(event.position):
                    fingers[event.index] = button.action
                    _set_action(button.action,true)
                    break
    elif event is InputEventScreenDrag and event.index == stick_finger:
        _set_stick(event.position)

func _set_stick(point: Vector2) -> void:
    stick = (point-CENTER).limit_length(RADIUS)
    _set_action("p1_left",stick.x < -10)
    _set_action("p1_right",stick.x > 10)
    _set_action("p1_up",stick.y < -12)
    _set_action("p1_down",stick.y > 12)

func _set_action(action: String, pressed: bool) -> void:
    if pressed and not held.has(action):
        held[action] = true
        Input.action_press(action)
    elif not pressed and held.has(action):
        held.erase(action)
        Input.action_release(action)

func _release_finger(index: int) -> void:
    if index == stick_finger:
        stick_finger = -1
        stick = Vector2.ZERO
        for action in DIRECTIONS:
            _set_action(action,false)
    if fingers.has(index):
        var action: String = fingers[index]
        fingers.erase(index)
        if not action in fingers.values():
            _set_action(action,false)

func release_all() -> void:
    for action: String in held.keys():
        _set_action(action,false)
    fingers.clear()
    stick_finger = -1
    stick = Vector2.ZERO

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
        release_all()

func _exit_tree() -> void:
    release_all()

func _draw() -> void:
    if not enabled:
        return
    draw_circle(CENTER+Vector2(0,2),RADIUS+2,Color(0,0,0,0.35))
    draw_circle(CENTER,RADIUS,Color("111d2ac9"))
    draw_arc(CENTER,RADIUS,0,TAU,40,Color(0.73,0.91,0.87,0.65),1)
    for data in [[Vector2(-19,3),"←"],[Vector2(12,3),"→"],[Vector2(-3,-15),"↑"],[Vector2(-3,23),"↓"]]:
        draw_string(UI_FONT,CENTER+data[0],data[1],HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color(0.9,1,1,0.7))
    draw_circle(CENTER+stick.limit_length(17),12,Color("d6fc63bb"))
    draw_arc(CENTER+stick.limit_length(17),12,0,TAU,32,Color("ebffc4"),1)
    for button in buttons:
        if button.action == "p1_fly" and fighter.roster_name() != "mavrin":
            continue
        var text: String = button.label
        if button.action == "toggle_audio":
            text = "ЗВУК" if GameConfig.sound_enabled else "ТИХО"
        var special: bool = button.slot >= 0
        var cd := 0
        if special:
            text = SPECIAL_NAMES[fighter.roster_name()][button.slot]
            cd = fighter.abilities.cooldowns[button.slot]
            if fighter.roster_name() == "rinat" and button.slot == 1 and fighter.abilities.rinat.master_frames > 0:
                text = "%.0f +25%%" % ceil(fighter.abilities.rinat.master_frames / 60.0)
            elif cd > 0:
                text = "%.1f" % (cd/60.0)
        var pressed: bool = held.has(button.action)
        var heavy: bool = button.action in ["p1_hp","p1_hk"]
        var utility: bool = button.action in ["ui_cancel","toggle_audio"]
        var accent := Color("d6fc63") if heavy or special else Color("a6cfef")
        var style := StyleBoxFlat.new()
        style.bg_color = Color("536a35ed") if pressed else (Color("25331ee0") if special else Color("172535d9"))
        style.border_color = Color("66717a") if cd > 0 else accent
        style.set_border_width_all(1)
        style.set_corner_radius_all(7 if not utility else 5)
        style.shadow_color = Color(0,0,0,0.3)
        style.shadow_size = 2
        var r: float = button.radius
        draw_style_box(style,Rect2(button.center-Vector2(r,r),Vector2(r*2,r*2)))
        if special and cd > 0:
            var total: float = Roster.COOLDOWNS[fighter.roster_name()][button.slot]
            draw_arc(button.center,r-2,-PI/2,-PI/2+TAU*clampf(cd/total,0,1),32,Color("9ac4df"),2)
        var size := 6 if text.length()>6 else (7 if special or utility else 11)
        draw_string(UI_FONT,button.center+Vector2(-r,size*0.34),text,HORIZONTAL_ALIGNMENT_CENTER,r*2,size,Color("8994a0") if cd>0 else Color("f4f5ec"))
