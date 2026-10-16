extends State

## Ejecutando un agarre (lado atacante): breve recuperación y vuelve a Idle.

func enter() -> void:
	fighter.stop_horizontal()

func physics_update(_delta: float) -> void:
	if state_frame >= 20:
		state_machine.transition_to("Idle")
