class_name MotionParser
extends RefCounted

## Detecta motions (236, 623, 214...) en un historial de direcciones numpad.
## history: array de numpad (1-9), índice 0 = frame más reciente.
## seq: secuencia en orden cronológico, p.ej. [2,3,6] para quarter-circle forward.
## window: frames máximos de separación permitidos entre pasos (leniency).
## Lógica pura -> testeable en unidad.
static func matches(history: Array, seq: Array, window: int) -> bool:
	if seq.is_empty():
		return true
	var need := seq.duplicate()
	need.reverse()   # buscar del más reciente al más antiguo
	var hi := 0
	for req in need:
		var found := false
		var steps := 0
		while hi < history.size() and steps <= window:
			if int(history[hi]) == int(req):
				found = true
				hi += 1
				break
			hi += 1
			steps += 1
		if not found:
			return false
	return true

## Convierte ejes (facing-relativos) a numpad. fwd/back: +1/-1 (relativo al facing);
## vertical: up=+1, down=-1.
static func to_numpad(fwd_back: int, vertical: int) -> int:
	var col := 1                       # 0=atrás, 1=neutro, 2=adelante
	if fwd_back > 0:
		col = 2
	elif fwd_back < 0:
		col = 0
	if vertical > 0:
		return [7, 8, 9][col]
	elif vertical < 0:
		return [1, 2, 3][col]
	return [4, 5, 6][col]
