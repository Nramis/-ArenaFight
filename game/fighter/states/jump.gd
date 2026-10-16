extends State

## En el aire: aplica gravedad; la velocidad horizontal quedó fija al despegar (sin
## control aéreo). Puede lanzar un normal aéreo ("j"). Al aterrizar vuelve a Idle.

func physics_update(delta: float) -> void:
	if fighter.try_start_attack("j"):
		state_machine.transition_to("Attack")
		return
	fighter.steer_air(delta)
	fighter.apply_gravity(delta)
	if fighter.on_ground:
		state_machine.transition_to("Idle")
