extends Node3D
class_name PuzzleWindow

@export var is_event_window: bool = false
@export var window_group: StringName = &"puzzle_window"

@export var focus_id: StringName = &"window"
@export var decorative_feedback: String = "É o vento só, e nada mais."

@export var click_area_path: NodePath = ^"ClickArea"

func _ready() -> void:
	if is_event_window:
		add_to_group(window_group)

	_configure_click_area()

func open_window() -> void:
	visible = false

func close_window() -> void:
	visible = true

func _configure_click_area() -> void:
	var click_area: Node = get_node_or_null(click_area_path)

	if click_area == null:
		push_warning("PuzzleWindow sem ClickArea em: %s" % click_area_path)
		return

	if click_area is FocusClickable:
		var focus_clickable := click_area as FocusClickable
		focus_clickable.focus_id = focus_id
		focus_clickable.is_enabled = true

	if click_area.has_method("configure_from_window"):
		click_area.call("configure_from_window", self)
