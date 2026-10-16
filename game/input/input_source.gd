class_name InputSource
extends Node

## Interfaz común de fuentes de input. El Fighter pide poll() cada tick y recibe un
## InputFrame, SIN saber si viene de un humano (teclado/mando) o de la IA.
## Las subclases (HumanInput, AIInput) sobreescriben poll().
func poll() -> InputFrame:
	return InputFrame.new()
