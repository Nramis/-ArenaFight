class_name AnimationTimeline
extends RefCounted

# Pose indices 0..7 are the base atlas; 8..15 are intermediate frames.
static func walk_pose(gait: float, extra: bool = true) -> int:
	return ([1,8,2,9] if extra else [1,0,2,0])[posmod(int(gait),4)]

static func attack_pose(frame: float, startup: int, active: int, recovery: int, kick: bool, extra: bool = true) -> int:
	var strike := 4 if kick else 3
	if frame < startup:
		return strike if frame/maxf(startup,1) > 0.7 else ((12 if kick else 10) if extra else 0)
	if frame < startup+active:
		return strike
	var progress := (frame-startup-active)/maxf(recovery,1)
	if progress < 0.2:
		return strike
	if progress < 0.78 and extra:
		return 13 if kick else 11
	return 0

static func knockdown_pose(frame: int, remaining: int) -> int:
	return 6 if frame < 6 else (14 if remaining > 12 else 15)
