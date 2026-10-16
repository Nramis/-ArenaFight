class_name StagePhysics
extends RefCounted

## Física de escenario pura y determinista: paredes (clamp) y separación de pushboxes.
## Sin nodos -> testeable en unidad.

## Mantiene x dentro de [left, right] (paredes del escenario).
static func clamp_wall(x: float, left: float, right: float) -> float:
	return clampf(x, left, right)

## Separa dos posiciones si están más cerca que min_sep (pushbox). Devuelve [x1', x2'].
## No pueden solaparse: se empujan mutuamente a partes iguales.
static func separate(x1: float, x2: float, min_sep: float) -> Array:
	var dx: float = x2 - x1
	var dist: float = abs(dx)
	if dist >= min_sep:
		return [x1, x2]
	var push: float = (min_sep - dist) / 2.0
	var dir: float = 1.0 if dx >= 0.0 else -1.0
	return [x1 - dir * push, x2 + dir * push]

# Airborne fighters can cross above another body; lateral hitboxes still resolve.
static func bodies_overlap_vertically(a: Fighter, b: Fighter) -> bool:
	var ah := (36.0 if a.is_crouching_pose() else 64.0)*a.abilities.size_multiplier()
	var bh := (36.0 if b.is_crouching_pose() else 64.0)*b.abilities.size_multiplier()
	return minf(a.position.y,b.position.y)-maxf(a.position.y-ah,b.position.y-bh) > 8.0

# Preserve separation at walls instead of clipping one half of the correction.
static func separate_bounded(x1: float, x2: float, min_sep: float, left: float, right: float) -> Array:
	var pair := separate(clampf(x1,left,right),clampf(x2,left,right),min_sep)
	if absf(pair[1]-pair[0]) >= min_sep and pair[0] >= left and pair[0] <= right and pair[1] >= left and pair[1] <= right:
		return pair
	var half := minf(min_sep,right-left)/2.0
	var center := clampf((pair[0]+pair[1])/2.0,left+half,right-half)
	return [center-half,center+half] if x2 >= x1 else [center+half,center-half]
