extends Node3D

@export var fragment_id: int = 1
@export var available: bool = true
@export var hide_until_available: bool = false
@export var title_label: Label3D

@export var required_focus_id: StringName = &""

signal fragment_collected(fragment_id: int)

@onready var click_area: Area3D = $ClickArea
@onready var collision_shape: CollisionShape3D = $ClickArea/CollisionShape3D

var collected: bool = false


func _ready() -> void:
	if title_label != null:
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_update_title_label()
	_apply_interaction_state()

func interact(camera_rig = null) -> void:
	if collected:
		return

	if not _is_focus_allowed(camera_rig):
		_show_feedback("Você precisa olhar mais de perto.")
		return

	if not available:
		_show_feedback("Ainda não consigo pegar este fragmento.")
		return

	collect()

func collect() -> void:
	collected = true

	GameState.collect_fragment(fragment_id)
	_show_feedback("Fragmento adicionado ao inventário.")

	fragment_collected.emit(fragment_id)

	_apply_interaction_state()
	call_deferred("queue_free")

func is_available() -> bool:
	return available and not collected

func set_available(value: bool) -> void:
	available = value
	_apply_interaction_state()

func _is_focus_allowed(camera_rig) -> bool:
	if required_focus_id == &"":
		return true

	if camera_rig == null:
		return false

	if not camera_rig.has_method("get_current_focus_id"):
		return false

	return camera_rig.get_current_focus_id() == required_focus_id

func _apply_interaction_state() -> void:
	var should_be_hidden := hide_until_available and not available and not collected
	var should_be_interactable := not collected and not should_be_hidden

	visible = not should_be_hidden

	if click_area:
		click_area.monitoring = should_be_interactable
		click_area.monitorable = should_be_interactable
		click_area.input_ray_pickable = should_be_interactable

	if collision_shape:
		collision_shape.disabled = not should_be_interactable

func _fit_label_font_size(label: Label3D, text: String, max_font_size: int = 128, min_font_size: int = 64) -> void:
	if label == null:
		return

	label.text = text
	label.font_size = max_font_size

	var font: Font = label.font

	if font == null:
		return

	var max_width: float = label.width

	if max_width <= 0.0:
		return

	for size in range(max_font_size, min_font_size - 1, -1):
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)

		if text_size.x <= max_width:
			label.font_size = size
			return

	label.font_size = min_font_size

func _update_title_label() -> void:
	if title_label == null:
		return

	var data: Dictionary = GameState.get_fragment_data(fragment_id)

	if data.is_empty():
		_fit_label_font_size(title_label, "Fragmento")
		return

	_fit_label_font_size(title_label, data["title"])

func _show_feedback(text: String) -> void:
	get_tree().call_group("ui", "show_feedback", text)
