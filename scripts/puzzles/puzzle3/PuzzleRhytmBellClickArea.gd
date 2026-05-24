extends Area3D
class_name PuzzleRhythmBellClickArea

@export var bell: PuzzleRhythmBell
@export var required_focus_id: StringName = &"stool"

func _ready() -> void:
	if bell == null:
		var parent := get_parent()

		if parent is PuzzleRhythmBell:
			bell = parent

func can_interact(camera_rig: Node) -> bool:
	if required_focus_id == &"":
		return true

	if camera_rig == null:
		return false

	if not camera_rig.has_method("get_current_focus_id"):
		return false

	return camera_rig.get_current_focus_id() == required_focus_id

func interact(camera_rig = null) -> void:
	if bell == null:
		push_warning("ClickArea do sino sem PuzzleRhythmBell configurado.")
		return

	bell.interact(camera_rig)
