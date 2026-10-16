class_name InputFrame
extends RefCounted

## Estado de input de UN frame. Es la "capa de botones virtuales": el Fighter
## solo conoce esto, nunca el teclado/mando directamente. Humano e IA lo producen igual.

# Direcciones
var left: bool = false
var right: bool = false
var up: bool = false
var down: bool = false

# Botones de ataque (aún sin usar en Fase 0; listos para las fases de combate)
var lp: bool = false
var mp: bool = false
var hp: bool = false
var lk: bool = false
var mk: bool = false
var hk: bool = false

## Eje horizontal en espacio de pantalla: -1 (izquierda), 0 (neutro), +1 (derecha).
func horizontal() -> int:
	return int(right) - int(left)

## Eje vertical: -1 (arriba), 0, +1 (abajo). (En pantalla, "abajo" es +Y.)
func vertical() -> int:
	return int(down) - int(up)
