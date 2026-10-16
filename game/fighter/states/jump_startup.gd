extends State

## Prejump: unos frames en el suelo antes de despegar (ventana comprometida).
## La dirección horizontal se fija al ENTRAR y no cambia (salto comprometido).

var _h: int = 0

func enter() -> void:
	fighter.stop_horizontal()
	_h = fighter.input.horizontal()

func physics_update(_delta: float) -> void:
	if state_frame >= fighter.jump_startup_frames:
		fighter.launch_jump(_h)
		state_machine.transition_to("Jump")
