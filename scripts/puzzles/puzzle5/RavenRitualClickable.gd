extends Area3D
class_name RavenRitualClickable

@export var required_focus_id: StringName = &"couch"
@export var ritual_group: StringName = &"raven_ritual"

func can_interact(camera_rig: Node) -> bool:
	if camera_rig == null:
		return false
	if not camera_rig.has_method("get_current_focus_id"):
		return false
	return camera_rig.get_current_focus_id() == required_focus_id

func interact(_camera_rig = null) -> void:
	if GameState.puzzle_state < 5:
		_show_feedback("A ave observa, mas ainda não responde.")
		return
	var ritual := get_tree().get_first_node_in_group(ritual_group)
	if ritual != null and ritual.has_method("start_ritual"):
		ritual.start_ritual()
	else:
		_show_feedback("O Corvo permanece imóvel.")

func _show_feedback(text: String) -> void:
	get_tree().call_group("ui", "show_feedback", text)
