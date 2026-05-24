extends FocusClickable
class_name WindowEventClickable

@export var controller_group: StringName = &"window_event_controller"

var window: PuzzleWindow
var controller: WindowEventController

func configure_from_window(source_window: PuzzleWindow) -> void:
	window = source_window

	if window != null:
		focus_id = window.focus_id

	if window != null and window.is_event_window:
		controller = get_tree().get_first_node_in_group(controller_group) as WindowEventController

func _ready() -> void:
	if window == null:
		window = _find_window()

	if window != null:
		focus_id = window.focus_id

	if window != null and window.is_event_window:
		controller = get_tree().get_first_node_in_group(controller_group) as WindowEventController

func can_interact(camera_rig: Node) -> bool:
	if _is_inside_own_focus(camera_rig):
		return true

	return super.can_interact(camera_rig)

func interact(camera_rig: Node) -> void:
	if _is_inside_own_focus(camera_rig):
		if window != null and window.is_event_window:
			_trigger_window_event()
		else:
			_show_feedback(_get_decorative_feedback())
		return

	super.interact(camera_rig)

func _trigger_window_event() -> void:
	if controller == null:
		controller = get_tree().get_first_node_in_group(controller_group) as WindowEventController

	if controller != null:
		controller.trigger_window_event()

func _is_inside_own_focus(camera_rig: Node) -> bool:
	if camera_rig == null:
		return false

	if not camera_rig.has_method("get_current_focus_id"):
		return false

	var current_focus_id: StringName = camera_rig.call("get_current_focus_id") as StringName

	return current_focus_id == focus_id

func _get_decorative_feedback() -> String:
	if window == null:
		return "É o vento só, e nada mais."

	return window.decorative_feedback

func _find_window() -> PuzzleWindow:
	var current: Node = self

	while current != null:
		if current is PuzzleWindow:
			return current

		current = current.get_parent()

	return null

func _show_feedback(text: String) -> void:
	get_tree().call_group("ui", "show_feedback", text)
