extends FocusClickable
class_name LenoraFrameClickable

var controller: PuzzleLenoraController

func _ready() -> void:
	controller = _find_lenora_controller()

func can_interact(camera_rig: Node) -> bool:
	if _is_lenora_solved():
		return true

	return super.can_interact(camera_rig)

func interact(camera_rig: Node) -> void:
	if _is_lenora_solved():
		_show_feedback("Essa, mais bela do que a aurora, a quem nos céus chamam Lenora!")
		return

	super.interact(camera_rig)

func _is_lenora_solved() -> bool:
	if controller != null and controller.solved:
		return true

	if GameState.puzzle_state > 2:
		return true

	return false

func _find_lenora_controller() -> PuzzleLenoraController:
	var current: Node = self

	while current != null:
		if current is PuzzleLenoraController:
			return current

		current = current.get_parent()

	return null

func _show_feedback(text: String) -> void:
	get_tree().call_group("ui", "show_feedback", text)
