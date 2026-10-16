class_name DamageCalculator
extends RefCounted

## Damage scaling de combos (tabla del GDD): 1º-2º hit 100%, 3º 80%, 4º 60%, 5º 40%,
## 6º+ 20%. hits_before = número de golpes previos del combo (combo_count - 1).
static func scaled_damage(base: int, hits_before: int) -> int:
	return int(round(base * _scale(hits_before)))

static func _scale(hits_before: int) -> float:
	match hits_before:
		0, 1:
			return 1.0
		2:
			return 0.8
		3:
			return 0.6
		4:
			return 0.4
		_:
			return 0.2
