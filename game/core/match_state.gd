class_name MatchState
extends RefCounted

## Flujo de combate puro y testeable: intro -> pelea -> fin de round -> fin de match.
## Best-of-3, timer de 99s, KO o decisión por vida al agotarse el tiempo.

const INTRO := 0
const FIGHT := 1
const ROUND_END := 2
const MATCH_END := 3

const ROUNDS_TO_WIN := 2
const ROUND_FRAMES := 99 * 60
const INTRO_FRAMES := 110
const ROUND_END_FRAMES := 100

var round_end_duration: int = ROUND_END_FRAMES
var phase: int = INTRO
var phase_frame: int = 0
var timer: int = ROUND_FRAMES
var p1_rounds: int = 0
var p2_rounds: int = 0
var last_winner: int = 0   # 1, 2, o 0 (empate)

## Avanza un frame. Devuelve un evento: "" | "fight" | "round_end" | "next_round" | "match_end".
func tick(p1_hp: int, p2_hp: int) -> String:
	phase_frame += 1
	match phase:
		INTRO:
			if phase_frame >= INTRO_FRAMES:
				_to(FIGHT)
				return "fight"
		FIGHT:
			if timer > 0:
				timer -= 1
			var w := _winner(p1_hp, p2_hp)
			if w >= 0:
				last_winner = w
				if w == 1:
					p1_rounds += 1
				elif w == 2:
					p2_rounds += 1
				_to(ROUND_END)
				return "round_end"
		ROUND_END:
			if phase_frame >= round_end_duration:
				if p1_rounds >= ROUNDS_TO_WIN or p2_rounds >= ROUNDS_TO_WIN:
					_to(MATCH_END)
					return "match_end"
				timer = ROUND_FRAMES
				_to(INTRO)
				return "next_round"
		MATCH_END:
			pass
	return ""

## 1/2 = ganador del round, 0 = empate, -1 = aún sin resolver.
func _winner(p1_hp: int, p2_hp: int) -> int:
	if p1_hp <= 0 and p2_hp <= 0:
		return 0
	if p2_hp <= 0:
		return 1
	if p1_hp <= 0:
		return 2
	if timer <= 0:
		if p1_hp > p2_hp:
			return 1
		if p2_hp > p1_hp:
			return 2
		return 0
	return -1

func _to(p: int) -> void:
	if p == ROUND_END:
		round_end_duration = ROUND_END_FRAMES
	phase = p
	phase_frame = 0

func match_over() -> bool:
	return phase == MATCH_END

func match_winner() -> int:
	if p1_rounds >= ROUNDS_TO_WIN:
		return 1
	if p2_rounds >= ROUNDS_TO_WIN:
		return 2
	return 0

func reset_match() -> void:
	p1_rounds = 0
	p2_rounds = 0
	last_winner = 0
	timer = ROUND_FRAMES
	_to(INTRO)

func timer_seconds() -> int:
	return int(ceil(timer / 60.0))
