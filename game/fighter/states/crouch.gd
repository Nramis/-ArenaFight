extends State

## Agachado. Puede lanzar normales agachado ("cr"). Al soltar abajo vuelve a Idle.

func enter() -> void:
	fighter.stop_horizontal()

func physics_update(_delta: float) -> void:
	if fighter.try_start_special():
		state_machine.transition_to("Attack")
		return
	if fighter.try_start_attack("cr"):
		state_machine.transition_to("Attack")
		return
	if not fighter.input.down:
		state_machine.transition_to("Idle")
