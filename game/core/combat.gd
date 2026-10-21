class_name Combat
extends RefCounted

## Resolución de un golpe: si el atacante tiene hitbox activo y solapa el hurtbox del
## defensor (y no ha golpeado ya con este move), aplica el impacto. Devuelve true si pegó.
## Separado en su propia clase para poder testearlo de forma directa.
static func resolve(attacker: Fighter, defender: Fighter) -> bool:
	if not attacker.is_attack_active():
		return false
	if attacker.move_has_hit:
		return false
	if defender.is_invulnerable():
		return false
	if not attacker.hitbox_rect().intersects(defender.hurtbox_rect()):
		return false
	attacker.move_has_hit = true
	var m: MoveData = attacker.current_move
	# Empowerment is spent only on a melee contact, including a guarding opponent.
	# Projectiles, throws and summoned helpers do not consume the punch.
	if attacker.abilities != null and not m.is_special and attacker.abilities.expansion.consume_one_punch():
		attacker.abilities.expansion.hero.begin(defender)
		# Damage and the hit popup occur on the cinematic's actual impact frame.
		return false
	elif defender.is_blocking(m):
		defender.receive_block(m, attacker.facing())
	else:
		defender.receive_hit(m, attacker.facing())
	attacker.set_hitstop(m.hitstop)
	defender.set_hitstop(m.hitstop)
	return true
