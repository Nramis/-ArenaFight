class_name MovePhase
extends RefCounted

## Resuelve en qué fase está un ataque según el frame (1-indexado) y su frame data.
## Lógica pura -> testeable en unidad. Convención: "startup N" = primer frame activo N.

const STARTUP := 0
const ACTIVE := 1
const RECOVERY := 2
const DONE := 3

static func phase_at(frame: int, startup: int, active: int, recovery: int) -> int:
	if frame < startup:
		return STARTUP
	if frame < startup + active:
		return ACTIVE
	if frame < startup + active + recovery:
		return RECOVERY
	return DONE
