extends Area3D
class_name PuzzleClockClickArea

func can_interact(camera_rig: Node) -> bool:
	var clock: PuzzleClock = _get_clock()

	if clock == null:
		return false

	if camera_rig == null:
		return false

	if not camera_rig.has_method("get_current_focus_id"):
		return false

	var current_focus_id: StringName = camera_rig.call("get_current_focus_id") as StringName

	if current_focus_id == clock.focus_parent_id:
		return true

	if current_focus_id == clock.focus_id:
		if clock.is_locked and clock.has_available_fragment_paper():
			return false

		return true

	return false

func interact(camera_rig: Node) -> void:
	var clock: PuzzleClock = _get_clock()

	if clock == null:
		return

	if not can_interact(camera_rig):
		return

	var current_focus_id: StringName = camera_rig.call("get_current_focus_id") as StringName

	if current_focus_id == clock.focus_parent_id:
		if camera_rig.has_method("try_focus"):
			camera_rig.call("try_focus", clock.focus_id)
		return

	if current_focus_id == clock.focus_id:
		clock.start_drag()

func _get_clock() -> PuzzleClock:
	var current_node: Node = get_parent()

	while current_node != null:
		var clock: PuzzleClock = current_node as PuzzleClock

		if clock != null:
			return clock

		current_node = current_node.get_parent()

	return null
