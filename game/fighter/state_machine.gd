class_name StateMachine
extends Node

## Coordinador de estados. NO contiene lógica de comportamiento: solo delega en el
## estado activo y ejecuta las transiciones que los propios estados piden.
## Los estados son nodos hijos de este nodo.

## Estado inicial (opcional). Si no se asigna, se usa el primer hijo de tipo State.
@export var initial_state: State

var current_state: State

## Inyecta el Fighter dueño en cada estado y arranca el estado inicial.
func setup(owner_fighter: Fighter) -> void:
	for child in get_children():
		if child is State:
			child.fighter = owner_fighter
			child.state_machine = self
	current_state = initial_state if initial_state != null else _first_state()
	if current_state != null:
		current_state.state_frame = 0
		current_state.enter()

func _first_state() -> State:
	for child in get_children():
		if child is State:
			return child
	return null

## Cambia al estado indicado por nombre de nodo (ej. "Walk", "Idle").
func transition_to(state_name: String) -> void:
	var next := get_node_or_null(NodePath(state_name)) as State
	if next == null:
		push_warning("StateMachine: estado inexistente '%s'" % state_name)
		return
	current_state.exit()
	current_state = next
	current_state.state_frame = 0
	current_state.enter()

## Fuerza un estado directamente (reset de round), sin exit del anterior.
func force_state(state_name: String) -> void:
	var next := get_node_or_null(NodePath(state_name)) as State
	if next == null:
		return
	current_state = next
	current_state.state_frame = 0
	current_state.enter()

## Llamado por el Fighter cada tick de física.
func physics_update(delta: float) -> void:
	if current_state != null:
		current_state.state_frame += 1
		current_state.physics_update(delta)
