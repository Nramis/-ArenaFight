extends State

## Ejecuta un ataque (normal o especial): startup -> active -> recovery según su frame
## data. El hitbox activo lo consulta MatchManager. Los normales cancelables pueden
## cancelarse a especial durante active/recovery. Los especiales pueden moverse (self_move)
## y lanzar proyectil.

var _started_airborne: bool = false

func enter() -> void:
	_started_airborne = not fighter.on_ground
	if fighter.on_ground:
		var m: MoveData = fighter.current_move
		if m.is_special and m.self_move.x != 0.0:
			fighter.vel.x = m.self_move.x * fighter.facing()
		else:
			fighter.stop_horizontal()

func physics_update(delta: float) -> void:
	if not fighter.on_ground:
		fighter.steer_air(delta)
		fighter.apply_gravity(delta)
	if _started_airborne and fighter.on_ground:
		state_machine.transition_to("Idle")
		return
	var m: MoveData = fighter.current_move
	var phase := MovePhase.phase_at(state_frame, m.startup, m.active, m.recovery)
	if phase == MovePhase.ACTIVE and not fighter._swing_sounded:
		fighter._swing_sounded = true
		fighter.emit_sound("swing_heavy" if m.damage >= 80 else "swing")
	# Cancel de normal a especial (a partir de que sale el golpe).
	if m.cancelable and state_frame >= m.startup and fighter.try_start_special():
		state_machine.transition_to("Attack")
		return
	if (phase == MovePhase.RECOVERY or (phase == MovePhase.ACTIVE and state_frame > m.startup)) and fighter.try_chain_normal():
		state_machine.transition_to("Attack")
		return
	# Proyectil (Hadouken): se genera una vez al entrar en activo.
	if m.spawns_projectile and not fighter._projectile_spawned and phase == MovePhase.ACTIVE:
		fighter.spawn_projectile(m)
		fighter._projectile_spawned = true
	if phase == MovePhase.DONE:
		state_machine.transition_to("Idle" if fighter.on_ground else "Jump")
