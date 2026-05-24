extends Area3D
class_name FocusClickable

@export var focus_id: StringName
@export var is_enabled: bool = true

func can_interact(camera_rig: Node) -> bool:
	if not is_enabled:
		return false

	if focus_id == &"":
		return false

	if camera_rig == null:
		return false

	if not camera_rig.has_method("can_focus_id"):
		return false

	return camera_rig.call("can_focus_id", focus_id)


func interact(camera_rig: Node) -> void:
	if not can_interact(camera_rig):
		return

	camera_rig.call("try_focus", focus_id)
