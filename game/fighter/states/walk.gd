extends State

## Caminar (adelante o atrás según el facing). Sale a Attack/Crouch/Jump/Dash/Idle.

func physics_update(_delta: float) -> void:
	if fighter.try_start_special():
		state_machine.transition_to("Attack")
		return
	if fighter.try_start_attack("st"):
		state_machine.transition_to("Attack")
		return
	var dash: int = fighter.consume_dash()
	if dash != 0:
		fighter.begin_dash(dash)
		state_machine.transition_to("Dash")
		return
	if fighter.input.down:
		state_machine.transition_to("Crouch")
		return
	if fighter.input.up:
		state_machine.transition_to("JumpStartup")
		return
	var dir: int = fighter.input.horizontal()
	if dir == 0:
		state_machine.transition_to("Idle")
		return
	fighter.walk(dir)
