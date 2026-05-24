extends FocusClickable
class_name CouchFocusClickable

@export var unlock_group: StringName = &"couch_focus"
@export var locked_feedback: String = "Busco ainda algum remédio à amarga, infinda, atroz saudade."

var focus_unlocked: bool = false

func _ready() -> void:
	add_to_group(unlock_group)

func can_interact(camera_rig: Node) -> bool:
	if focus_unlocked:
		return super.can_interact(camera_rig)

	return true

func interact(camera_rig: Node) -> void:
	if not focus_unlocked:
		_show_feedback(locked_feedback)
		return

	super.interact(camera_rig)

func unlock_focus() -> void:
	focus_unlocked = true

func lock_focus() -> void:
	focus_unlocked = false

func _show_feedback(text: String) -> void:
	get_tree().call_group("ui", "show_feedback", text)
