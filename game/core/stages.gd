class_name Stages
extends RefCounted
const IDS = ["rooftop","taneko","office"]
const NAMES = {"rooftop":"КРЫША · ПОСЛЕ ЗАКАТА","taneko":"ТАНЕКО · НОЧНАЯ СМЕНА","office":"ТАТНЕФТЬ · ПОСЛЕ СОВЕЩАНИЯ"}
static func valid(id: String) -> String:
	return id if id in IDS else "rooftop"
