extends CanvasLayer

var manager: MatchManager
var label: Label
var elapsed_frames := 0
var tip_index := 0
var previous_phase := -1

func _ready() -> void:
    manager = get_parent()
    layer = 7
    label = Label.new()
    label.position = Vector2(64, 51)
    label.size = Vector2(256, 26)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.add_theme_font_size_override("font_size", 8)
    label.add_theme_color_override("font_color", Color("f2e8c6"))
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var panel := StyleBoxFlat.new()
    panel.bg_color = Color(0.035, 0.055, 0.055, 0.86)
    panel.border_color = Color("75653e")
    panel.set_border_width_all(1)
    panel.set_corner_radius_all(4)
    label.add_theme_stylebox_override("normal", panel)
    add_child(label)

func _physics_process(_delta: float) -> void:
    var phase := manager.match_state.phase
    if phase != previous_phase:
        elapsed_frames = 0
        previous_phase = phase
    label.visible = false
    if phase != MatchState.FIGHT:
        return
    elapsed_frames += 1
    var cycle := posmod(elapsed_frames - 180, 900)
    if elapsed_frames < 180 or cycle >= 210:
        return
    tip_index = int((elapsed_frames - 180) / 900)
    var ruslan := manager.p1.roster_name() == "ruslan" or manager.p2.roster_name() == "ruslan"
    var tips := ["РУКА 1 → РУКА 2 → РУКА 3\nU → I → O · тяжёлый завершает комбо", "Чередуй удары: рука → нога → тяжёлый\nСледующее нажатие — после попадания", "Отход от врага — блок\nОтход + вниз — защита от подсечки"]
    if ruslan:
        tips = ["РУСЛАН · КОЛЛЕКТОР\nРУКА 1 → РУКА 2 → РУКА 3 · лечение за комбо", "РУСЛАН · ПЕНАЛЬТИ\nНОГА 1 → НОГА 2 → НОГА 3 · сильный отброс", "РУСЛАН · РЕФИНАНСИРОВАНИЕ\nРука → нога → тяжёлый · меняй рисунок", "КУБИКИ: дубль — денежный дождь\nДругой результат — −150 HP Руслану", "ЧЁРНЫЙ ДЕНЬ · оба игрока слепнут на 4 с\nУправление и бой продолжаются"]
    label.text = tips[tip_index % tips.size()]
    label.visible = true
