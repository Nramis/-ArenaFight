class_name DashInput
extends RefCounted

## Detecta el dash (doble toque de una dirección) a partir del eje horizontal por frame.
## Lógica pura y determinista -> testeable en unidad sin escena.
## update() se llama una vez por frame con el eje horizontal (-1/0/1) y devuelve
## la dirección del dash detectado ese frame (-1/0/1; 0 = sin dash).

var _last_dir: int = 0
var _frame: int = 0
var _last_tap_dir: int = 0
var _last_tap_frame: int = -1000

func update(dir_x: int, window: int = 12) -> int:
	_frame += 1
	var dash: int = 0
	# Flanco de subida: la dirección pasa de neutro a no-neutro (un "toque").
	if dir_x != 0 and _last_dir == 0:
		if dir_x == _last_tap_dir and (_frame - _last_tap_frame) <= window:
			dash = dir_x
		_last_tap_dir = dir_x
		_last_tap_frame = _frame
	_last_dir = dir_x
	return dash
