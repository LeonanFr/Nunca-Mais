@tool
extends Node3D
class_name PuzzleBook

@export var book_id: StringName = &""

@export var book_title: String = "Meia-Noite":
	set(value):
		book_title = value
		_update_visual()

@export_range(8, 96, 1) var title_font_size: int = 28:
	set(value):
		title_font_size = value
		_update_visual()

@export_range(0.001, 0.05, 0.001) var title_pixel_size: float = 0.006:
	set(value):
		title_pixel_size = value
		_update_visual()

@export var title_color: Color = Color(0.86, 0.75, 0.52, 1.0):
	set(value):
		title_color = value
		_update_visual()

@export var selected_title_color: Color = Color(1.0, 0.92, 0.45, 1.0):
	set(value):
		selected_title_color = value
		_update_visual()

@export var force_uppercase: bool = true:
	set(value):
		force_uppercase = value
		_update_visual()

@export var use_manual_line_breaks: bool = false:
	set(value):
		use_manual_line_breaks = value
		_update_visual()

@export_multiline var manual_title_text: String = "":
	set(value):
		manual_title_text = value
		_update_visual()

@export_group("Interaction")
@export var is_enabled: bool = true
@export var required_focus_id: StringName = &"puzzle_row"

var is_selected: bool = false


func _ready() -> void:
	_update_visual()


func set_selected(value: bool) -> void:
	is_selected = value
	_update_visual()


func can_interact(camera_rig: Node) -> bool:
	if Engine.is_editor_hint():
		return false

	if not is_enabled:
		return false

	if camera_rig == null:
		return false

	if not camera_rig.has_method("get_current_focus_id"):
		return false

	var current_focus: StringName = camera_rig.call("get_current_focus_id") as StringName

	return current_focus == required_focus_id


func interact(camera_rig: Node) -> void:
	if not can_interact(camera_rig):
		return

	var controller: Node = _find_books_controller()

	if controller == null:
		push_warning("Livro sem PuzzleBooksController acima dele na hierarquia.")
		return

	if not controller.has_method("handle_book_clicked"):
		push_warning("PuzzleBooksController não possui handle_book_clicked().")
		return

	controller.call("handle_book_clicked", self)


func _find_books_controller() -> Node:
	var current_node: Node = get_parent()

	while current_node != null:
		if current_node.has_method("handle_book_clicked"):
			return current_node

		current_node = current_node.get_parent()

	return null


func _update_visual() -> void:
	var label: Label3D = get_node_or_null("SpineLabelAnchor/TitleLabel") as Label3D

	if label == null:
		return

	var final_text: String = book_title

	if use_manual_line_breaks and not manual_title_text.is_empty():
		final_text = manual_title_text.replace("\\n", "\n")

	if force_uppercase:
		final_text = final_text.to_upper()

	label.text = final_text
	label.font_size = title_font_size
	label.pixel_size = title_pixel_size

	if is_selected:
		label.modulate = selected_title_color
	else:
		label.modulate = title_color
