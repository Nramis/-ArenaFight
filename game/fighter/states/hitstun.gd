extends State

## Aturdimiento al ser golpeado: no se puede actuar. El pushback decae y, al terminar
## los frames de hitstun (y estar en el suelo), vuelve a Idle.

func physics_update(delta: float) -> void:
	if not fighter.on_ground:
		fighter.apply_gravity(delta)
	fighter.vel.x = move_toward(fighter.vel.x, 0.0, 600.0 * delta)
	fighter.hitstun_frames -= 1
	if fighter.hitstun_frames <= 0 and fighter.on_ground:
		state_machine.transition_to("Idle")
