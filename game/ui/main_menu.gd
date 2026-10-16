extends Control

## Menú principal: elige modo (2 jugadores o vs CPU con dificultad) y arranca el match.

func _ready() -> void:
	$VBox/Btn2P.pressed.connect(_start.bind(false, "medium"))
	$VBox/BtnEasy.pressed.connect(_start.bind(true, "easy"))
	$VBox/BtnMedium.pressed.connect(_start.bind(true, "medium"))
	$VBox/BtnHard.pressed.connect(_start.bind(true, "hard"))

func _start(cpu: bool, difficulty: String) -> void:
	GameConfig.set_mode(cpu, difficulty)
	get_tree().change_scene_to_file("res://match/match.tscn")
