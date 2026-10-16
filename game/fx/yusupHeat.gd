extends CanvasLayer

var fighter: Fighter
var shade: ColorRect

func _ready() -> void:
    # Tint the arena and characters while leaving HUD and touch controls clear.
    layer = 0
    shade = ColorRect.new()
    shade.size = Vector2(384, 216)
    shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(shade)

func _process(_delta: float) -> void:
    if not is_instance_valid(fighter) or fighter.abilities.yusup.heat_frames <= 0:
        queue_free()
        return
    var strength := minf(1.0, fighter.abilities.yusup.heat_frames / 18.0)
    shade.color = Color(0.95, 0.06, 0.02, 0.28 * strength)
