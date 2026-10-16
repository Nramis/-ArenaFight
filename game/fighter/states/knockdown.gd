extends State

## Derribado (barrido o agarre): tirado en el suelo durante knockdown_frames; al
## terminar (y estar en el suelo) se levanta a Idle. (Wakeup simple, sin quick-rise.)

func physics_update(delta: float) -> void:
	if not fighter.on_ground:
		fighter.apply_gravity(delta)
	fighter.vel.x = move_toward(fighter.vel.x, 0.0, 800.0 * delta)
	fighter.knockdown_frames -= 1
	if fighter.knockdown_frames <= 0 and fighter.on_ground:
		fighter.invuln_frames = Fighter.WAKEUP_PROTECTION
		state_machine.transition_to("Idle")
