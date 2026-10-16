class_name Throws
extends RefCounted

## Resolución de agarres entre dos fighters. Si ambos intentan agarrar en rango el mismo
## frame -> throw tech (se separan, sin daño). Si solo uno -> agarra (knockdown al rival).
static func resolve(a: Fighter, b: Fighter, throw_range: float) -> void:
	var dist: float = absf(a.position.x - b.position.x)
	var a_try: bool = a.throw_pressed and dist <= throw_range and b.is_throwable()
	var b_try: bool = b.throw_pressed and dist <= throw_range and a.is_throwable()
	if a_try and b_try:
		a.throw_tech()
		b.throw_tech()
	elif a_try:
		a.do_throw(b)
	elif b_try:
		b.do_throw(a)
