extends Control

const PORTRAITS = {
	"rafael":[preload("res://assets/fighters.png"),Rect2(30,40,210,250)],
	"nikita":[preload("res://assets/fighters.png"),Rect2(30,534,210,250)],
	"vladislav":[preload("res://assets/vladislav.png"),Rect2(40,40,200,270)],
	"mavrin":[preload("res://assets/mavrin.png"),Rect2(90,15,235,260)],
	"ramis":[preload("res://assets/ramis.png"),Rect2(100,25,210,250)],
	"ilgiz":[preload("res://assets/newcomers.png"),Rect2(50,30,270,300)],
	"bigboss":[preload("res://assets/newcomers.png"),Rect2(50,542,270,300)],
	"azat":[preload("res://assets/azat.png"),Rect2(0,0,384,500)],
	"polina":[preload("res://assets/motion/polina.png"),Rect2(0,0,384,500)]
}
const DESCRIPTIONS = {
	"rafael":"Энергетик · Протеин · Волна изо рта",
	"nikita":"Зелёная ловушка · Берсерк · Чёрное пламя",
	"vladislav":"Бургеры · Неуязвимость от рыбы · Масса",
	"mavrin":"Словесные волны · Шпагат · Звонок · Полёт F / H",
	"ramis":"Марис · Солнечный рикошет · Геморройчики",
	"ilgiz":"Собаки · Уход на 6 с · Уменьшение и слабость на 6 с",
	"bigboss":"Пистолет · Автомат · Толпа с Тик Током",
	"azat":"Только нытьё · Жалобы · Никаких атак и урона",
	"polina":"Телепорт с ударом · Дождь · Случайный жест / ступор 3 с"
}
var selected := ["rafael","nikita"]
var active_slot := 0
var slots: Array[Button] = []
var cards: Array[Button] = []
var mode: OptionButton
var difficulty: OptionButton
var detail: Label
var stage_select: OptionButton

func _ready() -> void:
	selected = [Roster.valid(GameConfig.p1_character),Roster.valid(GameConfig.p2_character)]
	var bg := ColorRect.new()
	bg.color = Color("101828")
	bg.size = Vector2(384,216)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_label("ВЫБОР БОЙЦОВ",Vector2(12,4),Vector2(360,20),16)
	for i in 2:
		var slot := _button("",Vector2(12+i*184,29),Vector2(176,20),8)
		slot.pressed.connect(_set_slot.bind(i))
		slots.append(slot)
	for i in Roster.IDS.size():
		var id: String = Roster.IDS[i]
		var card := _button("",Vector2(10+(i%3)*124,53+int(i/3)*31),Vector2(118,29),9)
		card.pressed.connect(_select.bind(id))
		cards.append(card)
		var texture := AtlasTexture.new()
		texture.atlas = PORTRAITS[id][0]
		texture.region = PORTRAITS[id][1]
		var portrait := TextureRect.new()
		portrait.texture = texture
		portrait.position = Vector2(3,3)
		portrait.size = Vector2(25,25)
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(portrait)
		var name_label := Label.new()
		name_label.text = Roster.NAMES[id]
		name_label.position = Vector2(32,1)
		name_label.size = Vector2(82,26)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size",8)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name_label)
	detail = _label("",Vector2(12,147),Vector2(360,14),8)
	stage_select = OptionButton.new()
	stage_select.position = Vector2(12,161)
	stage_select.size = Vector2(360,14)
	stage_select.add_theme_font_size_override("font_size",8)
	for id in Stages.IDS:
		stage_select.add_item(Stages.NAMES[id])
	stage_select.select(Stages.IDS.find(GameConfig.stage_id))
	add_child(stage_select)
	mode = OptionButton.new()
	mode.position = Vector2(12,175)
	mode.size = Vector2(108,26)
	mode.add_theme_font_size_override("font_size",10)
	mode.add_item("Против ИИ")
	mode.add_item("Вдвоём")
	mode.select(0 if GameConfig.p2_is_cpu else 1)
	mode.item_selected.connect(_mode_changed)
	add_child(mode)
	difficulty = OptionButton.new()
	difficulty.position = Vector2(128,175)
	difficulty.size = Vector2(100,26)
	difficulty.add_theme_font_size_override("font_size",10)
	for text in ["Лёгкий ИИ","Средний ИИ","Сложный ИИ"]:
		difficulty.add_item(text)
	difficulty.select(["easy","medium","hard"].find(GameConfig.cpu_difficulty))
	add_child(difficulty)
	_mode_changed(mode.selected)
	var start := _button("НАЧАТЬ БОЙ  →",Vector2(240,175),Vector2(132,26),11)
	start.pressed.connect(_start)
	_label("Выбери слот, затем карточку · Tab: сменить слот · Enter: бой · Esc в бою: выбор",Vector2(12,205),Vector2(370,11),7)
	_refresh()
	if OS.has_feature("web") and GameConfig.quick_start:
		GameConfig.quick_start = false
		call_deferred("_start")

func _label(text: String, pos: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = dimensions
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("dce8e9"))
	add_child(label)
	return label

func _button(text: String, pos: Vector2, dimensions: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = dimensions
	button.add_theme_font_size_override("font_size",font_size)
	add_child(button)
	return button

func _set_slot(slot: int) -> void:
	active_slot = slot
	_refresh()

func _select(id: String) -> void:
	selected[active_slot] = Roster.valid(id)
	_refresh()

func _style(color: Color, selected_card: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("24364a") if selected_card else Color("172333")
	style.border_color = color
	style.set_border_width_all(2 if selected_card else 1)
	style.set_corner_radius_all(4)
	return style

func _refresh() -> void:
	for i in 2:
		slots[i].text = ("ИГРОК 1: " if i == 0 else "ПРОТИВНИК: ") + Roster.NAMES[selected[i]]
		slots[i].add_theme_stylebox_override("normal",_style(Color("9ee6d2") if i == 0 else Color("ecb18f"),active_slot == i))
	for i in cards.size():
		var chosen: bool = selected[active_slot] == Roster.IDS[i]
		cards[i].add_theme_stylebox_override("normal",_style(Color("9ee6d2") if active_slot == 0 else Color("ecb18f"),chosen))
	detail.text = DESCRIPTIONS[selected[active_slot]]

func _mode_changed(index: int) -> void:
	if difficulty != null:
		difficulty.disabled = index == 1

func _start() -> void:
	GameConfig.roster_enabled = true
	GameConfig.menu_open = false
	GameConfig.stage_id = Stages.IDS[stage_select.selected]
	GameConfig.p1_character = selected[0]
	GameConfig.p2_character = selected[1]
	GameConfig.set_mode(mode.selected == 0,["easy","medium","hard"][difficulty.selected])
	if OS.has_feature("web"):
		var payload := {"type":"arena-selection","p1":selected[0],"p2":selected[1],"mode":"cpu" if mode.selected == 0 else "2p","difficulty":GameConfig.cpu_difficulty,"stage":GameConfig.stage_id}
		JavaScriptBridge.eval("window.parent.postMessage("+JSON.stringify(payload)+",window.location.origin)")
	get_tree().change_scene_to_file("res://match/match.tscn")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_TAB:
			_set_slot(1-active_slot)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_ENTER:
			_start()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode in [KEY_LEFT,KEY_RIGHT]:
			var index := Roster.IDS.find(selected[active_slot])
			_select(Roster.IDS[posmod(index+(-1 if event.physical_keycode==KEY_LEFT else 1),Roster.IDS.size())])
