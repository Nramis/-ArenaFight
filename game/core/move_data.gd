class_name MoveData
extends Resource

## Datos de un ataque (frame data + geometría de golpe). Data-driven: se puede editar
## como .tres o construir por código (ver MoveSet). Separa los NÚMEROS de la lógica.

@export var move_name: String = ""
@export_group("Frame Data")
@export var startup: int = 4      # primer frame activo = startup (1-indexado)
@export var active: int = 3
@export var recovery: int = 8
@export_group("On Hit")
@export var damage: int = 30
@export var hitstun: int = 12
@export var blockstun: int = 9
@export var hitstop: int = 8
@export var pushback: float = 60.0
@export_group("Hitbox (relativo al origen del fighter, +x = adelante)")
@export var hitbox_offset: Vector2 = Vector2(32, -60)  # centro
@export var hitbox_size: Vector2 = Vector2(36, 24)
@export_group("Properties")
@export var hits_low: bool = false        # debe bloquearse abajo
@export var hits_overhead: bool = false   # debe bloquearse alto
@export var causes_knockdown: bool = false  # derriba (barridos, etc.)
@export var combo_finisher: bool = false
@export var cancelable: bool = false      # se puede cancelar a especial
@export_group("Special")
@export var is_special: bool = false
@export var spawns_projectile: bool = false
@export var projectile_speed: float = 0.0
@export var invuln_startup: int = 0       # frames de invencibilidad desde el inicio (DP)
@export var self_move: Vector2 = Vector2.ZERO  # velocidad propia durante el especial (x = adelante)

func total() -> int:
	return startup + active + recovery
