class_name FakeInput
extends InputSource

## Doble de test: una fuente de input controlable a mano. Permite a los tests de
## integración inyectar exactamente el input que quieren en el Fighter, sin teclado.
## Uso: var fake := FakeInput.new(); fake.frame.right = true

var frame: InputFrame = InputFrame.new()

func poll() -> InputFrame:
	return frame
