class_name HitSpark
extends Node2D

## Chispa de impacto: estrella que crece y se desvanece, luego se libera sola.
## Presentación pura, sin efecto en la lógica.

const DUR := 0.16

var _life: float = 0.0

func _ready() -> void:
	add_to_group("hitspark")

func _process(delta: float) -> void:
	_life += delta
	var t: float = _life / DUR
	if t >= 1.0:
		queue_free()
		return
	scale = Vector2.ONE * (0.9 + t * 2.6)
	modulate.a = 1.0 - t
