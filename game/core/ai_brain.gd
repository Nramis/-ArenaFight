class_name AIBrain
extends RefCounted

## Decisión táctica de la IA según la distancia y el estado del rival. Lógica pura
## (recibe un 'roll' 0..1 para la variedad, así es determinista y testeable).
## Devuelve una acción: "approach" | "retreat" | "attack" | "antiair" | "throw" | "block" | "idle".

const CLOSE := 55.0
const MID := 110.0
const ANTIAIR_RANGE := 100.0

static func decide(dist: float, opp_airborne: bool, opp_recovering: bool, roll: float) -> String:
	# Antiaéreo: prioridad si el rival salta cerca.
	if opp_airborne and dist < ANTIAIR_RANGE:
		return "antiair"
	if dist <= CLOSE:
		if roll < 0.55:
			return "attack"
		elif roll < 0.75:
			return "throw"
		else:
			return "block"
	elif dist <= MID:
		if opp_recovering:
			return "attack"          # whiff punish
		return "approach" if roll < 0.6 else "attack"
	else:
		return "approach"            # a distancia: acercarse
