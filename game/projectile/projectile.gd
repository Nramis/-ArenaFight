class_name Projectile
extends Node2D

## Proyectil (bola de fuego del Hadouken). Data-only: se mueve y golpea, pero el
## movimiento y la resolución los coordina MatchManager (determinista y centralizado).

var velocity_x: float = 0.0
var team: int = 0
var owner_facing: int = 1
var move: MoveData = null

func _ready() -> void:
	add_to_group("projectile")

func rect() -> Rect2:
	return Rect2(global_position.x - 12.0, global_position.y - 10.0, 24.0, 20.0)
