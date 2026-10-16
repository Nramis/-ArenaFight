class_name KfmFrames
extends RefCounted

## Construye el SpriteFrames de Kung Fu Man a partir de los PNG compuestos en
## assets/kfm/ y su manifest.json (frames, duraciones MUGEN, loop). Cacheado y
## compartido por ambos luchadores. axis = punto de alineación (pies) en el lienzo.

static var _cache: SpriteFrames = null
static var canvas: Vector2 = Vector2.ZERO
static var axis: Vector2 = Vector2.ZERO

static func get_frames() -> SpriteFrames:
	if _cache == null:
		_cache = _build()
	return _cache

static func _build() -> SpriteFrames:
	var f := FileAccess.open("res://assets/kfm/manifest.json", FileAccess.READ)
	if f == null:
		return null
	var m = JSON.parse_string(f.get_as_text())
	if m == null:
		return null
	canvas = Vector2(m["canvas"][0], m["canvas"][1])
	axis = Vector2(m["axis"][0], m["axis"][1])
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	for anim in m["anims"]:
		var info = m["anims"][anim]
		sf.add_animation(anim)
		sf.set_animation_loop(anim, bool(info["loop"]))
		sf.set_animation_speed(anim, 60.0)   # duraciones en ticks de 60 fps
		var n := int(info["frames"])
		for i in n:
			var tex = load("res://assets/kfm/%s/%03d.png" % [anim, i])
			if tex != null:
				sf.add_frame(anim, tex, float(info["durs"][i]))
	return sf
