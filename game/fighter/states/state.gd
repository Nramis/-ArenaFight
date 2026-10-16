class_name State
extends Node

## Clase base de todos los estados (contrato). Cada estado concreto hereda de aquí.
## Regla anti-espagueti: cada estado se ocupa SOLO de sí mismo y decide sus propias
## transiciones llamando a state_machine.transition_to("OtroEstado").

var fighter: Fighter                 # el personaje dueño (inyectado por la máquina)
var state_machine: StateMachine      # para pedir transiciones
var state_frame: int = 0             # frames transcurridos dentro de este estado

## Se llama UNA vez al entrar. Aquí: arrancar animación, fijar velocidad, etc.
func enter() -> void:
	pass

## Se llama UNA vez al salir. Aquí: limpiar timers, desconectar señales.
func exit() -> void:
	pass

## Lógica del estado cada tick de física (60 fps).
func physics_update(_delta: float) -> void:
	pass
