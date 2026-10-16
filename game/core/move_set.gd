class_name MoveSet
extends RefCounted

## Fábrica de los normales (18: 6 de pie, 6 agachado, 6 en el aire) con la frame data
## base del GDD. Devuelve un Dictionary "st.lp" -> MoveData. Los personajes pueden
## partir de aquí y ajustar. (Migrable a .tres cuando haya editor a mano.)

static func _m(nm: String, s: int, a: int, r: int, dmg: int, hs: int, bs: int, hstop: int, pb: float, off: Vector2, size: Vector2, low: bool = false, oh: bool = false, kd: bool = false) -> MoveData:
	var mv := MoveData.new()
	mv.move_name = nm
	mv.startup = s; mv.active = a; mv.recovery = r
	mv.damage = dmg; mv.hitstun = hs; mv.blockstun = bs; mv.hitstop = hstop; mv.pushback = pb
	mv.hitbox_offset = off; mv.hitbox_size = size
	mv.hits_low = low; mv.hits_overhead = oh; mv.causes_knockdown = kd
	return mv

static func default_normals() -> Dictionary:
	var d := {}
	# De pie
	d["st.lp"] = _m("st.LP", 4, 3, 7, 30, 12, 9, 8, 60.0, Vector2(32, -72), Vector2(34, 22))
	d["st.mp"] = _m("st.MP", 6, 3, 12, 60, 16, 12, 11, 80.0, Vector2(36, -72), Vector2(40, 24))
	d["st.hp"] = _m("st.HP", 9, 4, 18, 90, 20, 15, 14, 110.0, Vector2(40, -74), Vector2(44, 26))
	d["st.lk"] = _m("st.LK", 5, 3, 8, 30, 12, 9, 8, 60.0, Vector2(34, -40), Vector2(38, 22))
	d["st.mk"] = _m("st.MK", 7, 4, 14, 60, 16, 12, 11, 90.0, Vector2(44, -44), Vector2(46, 24))
	d["st.hk"] = _m("st.HK", 11, 4, 20, 90, 20, 15, 14, 120.0, Vector2(48, -48), Vector2(50, 28))
	# Heavy finishers: readable windup, punishable miss, a clean knockdown on hit.
	for key in ["st.hp","st.hk"]:
		d[key].combo_finisher = true
		d[key].startup += 2
		d[key].recovery += 4
		d[key].pushback = 320.0 if key == "st.hp" else 420.0
	# Agachado
	d["cr.lp"] = _m("cr.LP", 4, 3, 6, 25, 12, 9, 8, 50.0, Vector2(30, -38), Vector2(34, 20))
	d["cr.mp"] = _m("cr.MP", 6, 3, 11, 55, 16, 12, 11, 70.0, Vector2(34, -44), Vector2(38, 24))
	d["cr.hp"] = _m("cr.HP", 8, 4, 16, 85, 20, 14, 14, 60.0, Vector2(30, -58), Vector2(40, 44))
	d["cr.lk"] = _m("cr.LK", 5, 2, 7, 20, 12, 9, 7, 40.0, Vector2(32, -16), Vector2(38, 18), true)
	d["cr.mk"] = _m("cr.MK", 7, 3, 14, 55, 16, 12, 11, 70.0, Vector2(46, -18), Vector2(48, 20), true)
	d["cr.hk"] = _m("cr.HK", 9, 3, 22, 90, 22, 14, 14, 40.0, Vector2(48, -14), Vector2(52, 18), true, false, true)  # barrido: derriba
	# En el aire (recovery 0: duran hasta aterrizar)
	d["j.lp"] = _m("j.LP", 4, 6, 0, 30, 12, 9, 8, 40.0, Vector2(24, -60), Vector2(34, 26))
	d["j.mp"] = _m("j.MP", 6, 5, 0, 55, 16, 12, 11, 40.0, Vector2(28, -58), Vector2(38, 28))
	d["j.hp"] = _m("j.HP", 8, 4, 0, 90, 20, 14, 14, 40.0, Vector2(30, -56), Vector2(42, 30), false, true)
	d["j.lk"] = _m("j.LK", 5, 8, 0, 30, 12, 9, 8, 40.0, Vector2(24, -52), Vector2(34, 26))
	d["j.mk"] = _m("j.MK", 7, 5, 0, 55, 16, 12, 11, 40.0, Vector2(28, -50), Vector2(38, 28))
	d["j.hk"] = _m("j.HK", 9, 4, 0, 90, 20, 14, 14, 40.0, Vector2(30, -48), Vector2(42, 30), false, true)
	for key in d:
		if str(key).begins_with("j."):
			d[key].hits_overhead = true
	# Normales cancelables a especial (base de los combos por cancel).
	for k in ["st.lp", "st.mp", "st.lk", "st.mk", "cr.lp", "cr.mp", "cr.lk", "cr.mk"]:
		d[k].cancelable = true
	return d

## Especiales de un shoto: Hadouken (236P), Shoryuken (623P), Tatsu (214K), en L/M/H.
static func default_specials() -> Dictionary:
	var d := {}
	# Hadouken: proyectil (sin hitbox directo; el proyectil golpea). L/M/H = velocidad.
	var had := {"l": 180.0, "m": 260.0, "h": 340.0}
	for k in had:
		var mv := _m("Hadouken", 11, 2, 34, 60, 16, 12, 8, 20.0, Vector2(40, -60), Vector2(0, 0))
		mv.is_special = true
		mv.spawns_projectile = true
		mv.projectile_speed = had[k]
		d["hadouken." + k] = mv
	# Shoryuken: antiaéreo con invencibilidad al inicio. L/M/H = daño.
	var dp := {"l": [3, 80], "m": [4, 100], "h": [5, 120]}
	for k in dp:
		var mv := _m("Shoryuken", dp[k][0], 6, 26, dp[k][1], 20, 14, 14, 40.0, Vector2(28, -90), Vector2(40, 72))
		mv.is_special = true
		mv.invuln_startup = 6
		mv.self_move = Vector2(40.0, 0.0)
		d["dp." + k] = mv
	# Tatsu: ataque que avanza. L/M/H = daño/distancia.
	var ta := {"l": [70, 200.0], "m": [85, 240.0], "h": [100, 280.0]}
	for k in ta:
		var mv := _m("Tatsu", 11, 8, 12, ta[k][0], 16, 12, 11, 40.0, Vector2(30, -50), Vector2(44, 40))
		mv.is_special = true
		mv.self_move = Vector2(ta[k][1], 0.0)
		d["tatsu." + k] = mv
	return d
