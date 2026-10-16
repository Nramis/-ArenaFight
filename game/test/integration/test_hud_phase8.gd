# Integración Fase 8: el HUD refleja la vida de los fighters.
extends GdUnitTestSuite

const HUD_SCENE := preload("res://ui/hud.tscn")
const FIGHTER := preload("res://fighter/fighter.tscn")

func _setup() -> HUD:
	var hud: HUD = HUD_SCENE.instantiate()
	add_child(hud)
	auto_free(hud)
	var a: Fighter = FIGHTER.instantiate()
	var b: Fighter = FIGHTER.instantiate()
	add_child(a); add_child(b)
	auto_free(a); auto_free(b)
	hud.setup(a, b)
	return hud

func test_full_health_is_full_bar() -> void:
	var hud := _setup()
	hud._process(0.0)
	assert_float(hud.p1_fill.size.x).is_equal_approx(hud.BAR_W, 0.5)

func test_half_health_is_half_bar() -> void:
	var hud := _setup()
	hud.p1.health = hud.p1.max_health / 2
	hud._process(0.0)
	assert_float(hud.p1_fill.size.x).is_equal_approx(hud.BAR_W * 0.5, 1.0)

func test_p2_bar_drains_toward_center() -> void:
	var hud := _setup()
	hud.p2.health = hud.p2.max_health / 2
	hud._process(0.0)
	# la mitad derecha se mantiene fija; el borde izquierdo del fill se desplaza a la derecha
	assert_float(hud.p2_fill.size.x).is_equal_approx(hud.BAR_W * 0.5, 1.0)
	assert_float(hud.p2_fill.position.x).is_greater(204.0)
