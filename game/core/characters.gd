class_name Characters
extends RefCounted

## Diferenciación de los 2 shotos: mismos inputs, distintas propiedades.
##  - Kaze  (zoner paciente): mejor fireball (menos recovery), DP fiable, movilidad normal.
##  - Homura (rushdown):      fireball peor (más recovery), más movilidad, DP más fuerte.

static func stats(id: String) -> Dictionary:
	match id:
		"homura":
			return {
				"walk_fwd_speed": 210.0, "walk_back_speed": 160.0,
				"dash_fwd_speed": 470.0, "dash_fwd_frames": 12,
				"dash_back_speed": 400.0, "dash_back_frames": 12,
			}
		_:  # kaze (por defecto)
			return {
				"walk_fwd_speed": 180.0, "walk_back_speed": 140.0,
				"dash_fwd_speed": 420.0, "dash_fwd_frames": 16,
				"dash_back_speed": 360.0, "dash_back_frames": 14,
			}

static func specials_for(id: String) -> Dictionary:
	var d := MoveSet.default_specials()
	if id == "homura":
		for k in ["hadouken.l", "hadouken.m", "hadouken.h"]:
			d[k].recovery = 42          # fireball peor
		for k in ["dp.l", "dp.m", "dp.h"]:
			d[k].damage += 10           # DP más fuerte
	else:  # kaze
		for k in ["hadouken.l", "hadouken.m", "hadouken.h"]:
			d[k].recovery = 30          # mejor fireball
	return d
