class_name Sfx
extends Node

# Combat recordings plus a separately attributed Toasty excerpt. Bounded voice pool.
const FILES = {
	"toasty":["toasty-mk.mp3"],
	"combo":["arena_combo.wav"],
	"combo_finish":["arena_finish.wav"],
	"counter":["arena_counter.wav"],
	"knockdown":["arena_bodyfall.wav"],
	"round":["arena_round.wav"],
	"pistol":["laserSmall_000.ogg","laserSmall_001.ogg"],
	"rifle":["laserRetro_000.ogg"],
	"vanish":["forceField_000.ogg"],
	"step":["footstep_concrete_000.ogg","footstep_concrete_001.ogg","footstep_concrete_002.ogg"],
	"land":["impactSoft_heavy_000.ogg"],
	"swing":["swish-1.wav","swish-2.wav","swish-3.wav"],
	"swing_heavy":["arena_heavy_air.wav","swish-5.wav","swish-8.wav"],
	"hit":["impactPunch_medium_000.ogg","impactPunch_medium_001.ogg","impactPunch_medium_002.ogg"],
	"hit_heavy":["impactPunch_heavy_000.ogg","impactPunch_heavy_001.ogg"],
	"block":["impactPlate_light_000.ogg","impactPlate_light_001.ogg"],
	"buff":["clothBelt.ogg","beltHandle1.ogg"],
	"item":["metalClick.ogg"],
	"trap":["impactGlass_light_000.ogg"],
	"beam":["impactBell_heavy_000.ogg"],
	"summon":["cloth1.ogg","cloth2.ogg"],
	"phone":["metalClick.ogg"],
	"ko":["impactSoft_heavy_000.ogg"]
}
const VOLUMES = {"toasty":-13.0,"combo":-21.0,"combo_finish":-18.0,"counter":-22.0,"knockdown":-12.0,"round":-21.0,"step":-23.0,"land":-16.0,"swing":-19.0,"swing_heavy":-17.0,"hit":-12.0,"hit_heavy":-12.0,"block":-16.0,"buff":-16.0,"item":-18.0,"trap":-18.0,"beam":-24.0,"summon":-17.0,"phone":-16.0,"ko":-11.0,"pistol":-19.0,"rifle":-22.0}
var _cosmetic_rng := RandomNumberGenerator.new()
var bank: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _last_play: Dictionary = {}

func _ready() -> void:
	_cosmetic_rng.randomize()
	if AudioServer.get_bus_index("ArenaSFX") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count-1,"ArenaSFX")
	for event: String in FILES:
		var streams: Array[AudioStream] = []
		for file: String in FILES[event]:
			streams.append(load("res://assets/sfx/"+file) as AudioStream)
		bank[event] = streams
	for i in 10:
		var voice := AudioStreamPlayer.new()
		voice.bus = "ArenaSFX"
		add_child(voice)
		voices.append(voice)
	GameConfig.apply_audio()

func play_event(event: String) -> void:
	if not GameConfig.sound_enabled or GameConfig.sound_volume <= 0 or not bank.has(event):
		return
	var now := Time.get_ticks_msec()
	if now-int(_last_play.get(event,-1000)) < (60 if event == "step" else 25):
		return
	_last_play[event] = now
	var voice: AudioStreamPlayer = voices[_next_voice]
	_next_voice = (_next_voice+1)%voices.size()
	voice.stream = bank[event][_cosmetic_rng.randi_range(0,bank[event].size()-1)]
	voice.volume_db = VOLUMES.get(event,-17.0)
	voice.pitch_scale = 1.0 if event == "toasty" else _cosmetic_rng.randf_range(0.96,1.04)
	voice.play()

func play_hit(blocked: bool = false, damage: int = 60) -> void:
	play_event("block" if blocked else ("hit_heavy" if damage >= 80 else "hit"))

func play_ko() -> void:
	play_event("ko")

func _exit_tree() -> void:
	for voice in voices:
		if is_instance_valid(voice):
			voice.stop()
			voice.stream = null
	voices.clear()
	bank.clear()
