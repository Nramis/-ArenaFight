extends Node2D

var direction := 1
var damage := 40
var age := 0.0
var particles: Array[Vector2] = []
var speeds: Array[Vector2] = []

func _ready() -> void:
    z_index = 8
    var visual_rng := RandomNumberGenerator.new()
    visual_rng.randomize()
    for i in clampi(6 + damage / 12, 7, 23):
        particles.append(Vector2.ZERO)
        speeds.append(Vector2(direction * visual_rng.randf_range(25, 115), visual_rng.randf_range(-115, 15)))

func _process(delta: float) -> void:
    var arena := get_parent() as MatchManager
    if arena != null and (arena.get_tree().paused or GameConfig.menu_open):
        return
    age += delta
    for i in particles.size():
        speeds[i].y += 290 * delta
        particles[i] += speeds[i] * delta
        particles[i].y = minf(particles[i].y, 180 - position.y)
    if age > 0.65:
        queue_free()
    queue_redraw()

func _draw() -> void:
    var alpha := clampf((0.65 - age) / 0.25, 0, 1)
    for i in particles.size():
        draw_line(particles[i], particles[i] - speeds[i].normalized() * (3 if i % 3 == 0 else 1.5), Color(0.6 + (i % 3) * 0.1, 0.025, 0.045, alpha), 1.3)
