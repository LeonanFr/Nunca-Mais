extends FocusClickable
class_name PuzzleDoorClickableArea

var door: PuzzleDoor

func _ready() -> void:
	door = _find_door()

func can_interact(camera_rig: Node) -> bool:
	if door != null:
		if _is_inside_open_door_focus(camera_rig):
			if door.has_available_fragment_paper():
				return false

			return true

		if _is_inside_closed_door_focus(camera_rig):
			return true

	return super.can_interact(camera_rig)

func interact(camera_rig: Node) -> void:
	if door != null:
		if _is_inside_open_door_focus(camera_rig):
			if door.has_available_fragment_paper():
				return

			door.show_darkness_feedback()
			return

		if _is_inside_closed_door_focus(camera_rig):
			door.interact_closed_door()
			return

	super.interact(camera_rig)

func _is_inside_open_door_focus(camera_rig: Node) -> bool:
	if door == null:
		return false

	if not door.opened:
		return false

	if camera_rig == null:
		return false

	if not camera_rig.has_method("get_current_focus_id"):
		return false

	var current_focus_id: StringName = camera_rig.call("get_current_focus_id") as StringName

	return current_focus_id == door.open_focus_id

func _is_inside_closed_door_focus(camera_rig: Node) -> bool:
	if door == null:
		return false

	if door.opened:
		return false

	if camera_rig == null:
		return false

	if not camera_rig.has_method("get_current_focus_id"):
		return false

	var current_focus_id: StringName = camera_rig.call("get_current_focus_id") as StringName

	return current_focus_id == door.closed_focus_id

func _find_door() -> PuzzleDoor:
	var current: Node = self

	while current != null:
		if current is PuzzleDoor:
			return current

		current = current.get_parent()

	return null
