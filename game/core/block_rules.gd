class_name BlockRules
extends RefCounted

## Reglas puras de bloqueo por dirección (testeable en unidad):
##  - Bloqueo de pie (atrás, sin abajo): defiende medios y overheads; NO bajos.
##  - Bloqueo agachado (abajo-atrás): defiende medios y bajos; NO overheads.
##  - Sin mantener atrás: no bloquea.
static func can_block(holding_back: bool, crouching: bool, hits_low: bool, hits_overhead: bool) -> bool:
	if not holding_back:
		return false
	if crouching:
		return not hits_overhead
	return not hits_low
