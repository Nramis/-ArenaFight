class_name CombatRhythm
extends RefCounted

const MAX_STAMINA := 100.0
var stamina := MAX_STAMINA
var previous_button := ""
var repeats := 0
var repeat_window := 0
var regen_delay := 0
var warning_frames := 0
var warning := ""
var depleted_frames := 0

func tick() -> void:
    repeat_window = maxi(0,repeat_window-1)
    regen_delay = maxi(0,regen_delay-1)
    warning_frames = maxi(0,warning_frames-1)
    if depleted_frames > 0:
        depleted_frames -= 1
        stamina = 0.0
        return
    if repeat_window == 0:
        repeats = 0
        previous_button = ""
    if regen_delay == 0:
        stamina = minf(MAX_STAMINA,stamina+0.3)

func try_normal(button: String, free: bool = false) -> Dictionary:
    var next_repeats := repeats+1 if button == previous_button and repeat_window > 0 else 1
    if next_repeats > 3:
        warning = "СМЕНИ УДАР"
        warning_frames = 60
        return {}
    var costs := {"lp":9.0,"lk":9.0,"mp":14.0,"mk":14.0,"hp":19.0,"hk":19.0}
    var cost: float = costs.get(button,14.0)+(next_repeats-1)*6
    if not free and stamina < cost:
        warning = "ПЕРЕДОХНИ"
        warning_frames = 60
        return {}
    if not free:
        stamina -= cost
    regen_delay = 36
    repeats = next_repeats
    previous_button = button
    repeat_window = 120
    return {"damage":maxf(0.6,1.0-(repeats-1)*0.15),"recovery":(repeats-1)*4}

func reset() -> void:
    depleted_frames = 0
    stamina = MAX_STAMINA
    previous_button = ""
    repeats = 0
    repeat_window = 0
    regen_delay = 0
    warning_frames = 0
    warning = ""

func deplete(duration: int) -> void:
    depleted_frames = maxi(depleted_frames, duration)
    stamina = 0.0
    regen_delay = 0
