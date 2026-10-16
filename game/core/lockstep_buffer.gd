class_name LockstepBuffer
extends RefCounted
var frame := 0
var delay := 6
var local_inputs: Dictionary = {}
var remote_inputs: Dictionary = {}
func reset(input_delay: int = 6) -> void:
	frame = 0
	delay = clampi(input_delay,3,12)
	local_inputs.clear()
	remote_inputs.clear()
	for i in delay:
		local_inputs[i] = 0
		remote_inputs[i] = 0
func receive(f: int, mask: int) -> bool:
	if f < frame or f > frame+240 or mask < 0 or mask > 16383:
		return false
	if remote_inputs.has(f):
		return remote_inputs[f] == mask
	remote_inputs[f] = mask
	return true
func queue_local(mask: int) -> int:
	var future := frame+delay
	if local_inputs.has(future):
		return -1
	local_inputs[future] = clampi(mask,0,16383)
	return future
func ready() -> bool:
	return local_inputs.has(frame) and remote_inputs.has(frame)
func advance() -> Array:
	if not ready():
		return []
	var pair := [local_inputs[frame],remote_inputs[frame]]
	local_inputs.erase(frame)
	remote_inputs.erase(frame)
	frame += 1
	return pair
