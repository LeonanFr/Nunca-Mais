extends Area3D

@export var required_focus_id: StringName = &"book"

func interact(camera_rig: Node = null) -> void:
	if not _is_focus_allowed(camera_rig):
		return

	var item: Node = _get_item()

	if item == null:
		return

	if item.has_method("interact"):
		item.call("interact", camera_rig)

func _is_focus_allowed(camera_rig: Node) -> bool:
	if required_focus_id == &"":
		return true

	if camera_rig == null:
		return false

	if not camera_rig.has_method("get_current_focus_id"):
		return false

	return camera_rig.call("get_current_focus_id") == required_focus_id


func _get_item() -> Node:
	var current_node: Node = get_parent()

	while current_node != null:
		if current_node.has_method("setup") and current_node.has_method("interact"):
			return current_node

		current_node = current_node.get_parent()

	return null
