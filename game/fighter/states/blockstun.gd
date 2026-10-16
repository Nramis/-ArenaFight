extends State

## Bloqueando: no se puede actuar durante blockstun_frames; luego vuelve a Idle.

func physics_update(delta: float) -> void:
	fighter.vel.x = move_toward(fighter.vel.x, 0.0, 600.0 * delta)
	fighter.blockstun_frames -= 1
	if fighter.blockstun_frames <= 0:
		state_machine.transition_to("Idle")
