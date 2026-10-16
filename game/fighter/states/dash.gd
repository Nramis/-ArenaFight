extends State

## Dash: ráfaga horizontal durante N frames (fijados en begin_dash), luego Idle.
## Comprometido: ignora el resto de inputs mientras dura.

func physics_update(_delta: float) -> void:
	if state_frame >= fighter.dash_frames_current:
		state_machine.transition_to("Idle")

func exit() -> void:
	fighter.stop_horizontal()
