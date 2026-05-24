extends CanvasLayer

@onready var hud: Control = $HUD
@onready var hud_margin: MarginContainer = $HUD/TopLeftMargin
@onready var hud_vbox: VBoxContainer = $HUD/TopLeftMargin/VBox

@onready var objective_label: Label = $HUD/TopLeftMargin/VBox/ObjectiveLabel
@onready var feedback_label: Label = $HUD/TopLeftMargin/VBox/FeedbackLabel
@onready var pending_fragment_label: Label = $HUD/TopLeftMargin/VBox/PendingFragmentLabel

@onready var inventory_panel: PanelContainer = $HUD/InventoryPanel
@onready var inventory_margin: MarginContainer = $HUD/InventoryPanel/Margin
@onready var inventory_vbox: VBoxContainer = $HUD/InventoryPanel/Margin/VBox
@onready var inventory_title: Label = $HUD/InventoryPanel/Margin/VBox/InventoryTitle

@onready var read_panel: Control = $ReadPanel
@onready var background: ColorRect = $ReadPanel/Background
@onready var bottom_bar: ColorRect = $ReadPanel/BottomBar
@onready var read_margin: MarginContainer = $ReadPanel/BottomBar/Margin
@onready var read_vbox: VBoxContainer = $ReadPanel/BottomBar/Margin/VBox

@onready var read_title_label: Label = $ReadPanel/BottomBar/Margin/VBox/TitleLabel
@onready var read_body_text: RichTextLabel = $ReadPanel/BottomBar/Margin/VBox/BodyText
@onready var close_hint_label: Label = $ReadPanel/BottomBar/Margin/VBox/CloseHintLabel

@onready var end_game_panel: Control = $EndGamePanel
@onready var end_fade_rect: ColorRect = $EndGamePanel/FadeRect
@onready var end_center: CenterContainer = $EndGamePanel/Center
@onready var end_vbox: VBoxContainer = $EndGamePanel/Center/VBox
@onready var end_title: Label = $EndGamePanel/Center/VBox/EndTitle
@onready var end_subtitle: Label = $EndGamePanel/Center/VBox/EndSubtitle

var inventory_slots: Array[Button] = []

var modal_open: bool = false
var reading_open: bool = false
var ending_open: bool = false
var feedback_tween: Tween = null

func _ready() -> void:
	add_to_group("ui")
	_set_mouse_filter_recursive(self, Control.MOUSE_FILTER_IGNORE)

	_cache_inventory_slots()
	_apply_visual_style()
	_configure_inventory_mouse_filter()
	_connect_inventory_slots()
	_render_inventory()

	read_panel.visible = false
	end_game_panel.visible = false
	feedback_label.text = ""
	pending_fragment_label.text = ""
	close_hint_label.text = "Esc / Clique para fechar"

	GameState.objective_changed.connect(_on_objective_changed)
	GameState.fragment_collected.connect(_on_fragment_inventory_changed)
	GameState.fragment_registered.connect(_on_fragment_inventory_changed)
	GameState.fragment_read.connect(_on_fragment_inventory_changed)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.inventory_selection_changed.connect(_on_inventory_selection_changed)

	update_objective(GameState.get_current_objective())
	update_pending_fragment_label()

func _input(event: InputEvent) -> void:
	if not reading_open:
		return

	if event.is_action_pressed("camera_back") or event.is_action_pressed("ui_cancel"):
		hide_fragment_panel()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed:
		hide_fragment_panel()
		get_viewport().set_input_as_handled()
		return

func update_objective(text: String) -> void:
	objective_label.text = text

func show_feedback(text: String, duration: float = 2.4) -> void:
	feedback_label.text = text
	feedback_label.modulate.a = 1.0

	if feedback_tween != null:
		feedback_tween.kill()

	feedback_tween = create_tween()
	feedback_tween.tween_interval(duration)
	feedback_tween.tween_property(feedback_label, "modulate:a", 0.0, 0.4)

func show_fragment(title: String, body: String) -> void:
	reading_open = true

	read_title_label.text = title
	read_body_text.text = body

	read_panel.visible = true

	await get_tree().process_frame
	_resize_read_panel_to_text()

func hide_fragment_panel() -> void:
	reading_open = false
	read_panel.visible = false

func set_modal_open(value: bool) -> void:
	modal_open = value

func blocks_world_input() -> bool:
	return reading_open or modal_open or ending_open

func update_pending_fragment_label() -> void:
	var selected_item: Dictionary = GameState.get_selected_inventory_item_data()

	if not selected_item.is_empty():
		pending_fragment_label.text = "Selecionado: " + str(selected_item.get("name", "Item"))
		return

	var pending_count: int = GameState.get_pending_fragment_ids().size()

	if pending_count <= 0:
		pending_fragment_label.text = ""
	elif pending_count == 1:
		pending_fragment_label.text = "Selecione um item no inventário."
	else:
		pending_fragment_label.text = str(pending_count) + " itens para usar."

func _on_objective_changed(new_objective: String) -> void:
	update_objective(new_objective)

func _on_fragment_inventory_changed(_fragment_id: int) -> void:
	update_pending_fragment_label()

func _cache_inventory_slots() -> void:
	inventory_slots.clear()

	inventory_slots.append($HUD/InventoryPanel/Margin/VBox/Slot)
	inventory_slots.append($HUD/InventoryPanel/Margin/VBox/Slot2)
	inventory_slots.append($HUD/InventoryPanel/Margin/VBox/Slot3)
	inventory_slots.append($HUD/InventoryPanel/Margin/VBox/Slot4)
	inventory_slots.append($HUD/InventoryPanel/Margin/VBox/Slot5)
	inventory_slots.append($HUD/InventoryPanel/Margin/VBox/Slot6)
	inventory_slots.append($HUD/InventoryPanel/Margin/VBox/Slot7)
	inventory_slots.append($HUD/InventoryPanel/Margin/VBox/Slot8)

func _apply_visual_style() -> void:
	background.color = Color(0.0, 0.0, 0.0, 0.28)
	bottom_bar.color = Color(0.0, 0.0, 0.0, 0.72)

	hud.anchor_left = 0.0
	hud.anchor_top = 0.0
	hud.anchor_right = 1.0
	hud.anchor_bottom = 1.0
	hud.offset_left = 0.0
	hud.offset_top = 0.0
	hud.offset_right = 0.0
	hud.offset_bottom = 0.0

	hud_margin.anchor_left = 0.0
	hud_margin.anchor_top = 0.0
	hud_margin.anchor_right = 0.0
	hud_margin.anchor_bottom = 0.0
	hud_margin.offset_left = 32.0
	hud_margin.offset_top = 24.0
	hud_margin.offset_right = 880.0
	hud_margin.offset_bottom = 208.0

	hud_margin.add_theme_constant_override("margin_left", 0)
	hud_margin.add_theme_constant_override("margin_top", 0)
	hud_margin.add_theme_constant_override("margin_right", 0)
	hud_margin.add_theme_constant_override("margin_bottom", 0)

	hud_vbox.add_theme_constant_override("separation", 4)

	_apply_label_style(objective_label, 64, Color("#F2E8C9"))
	objective_label.custom_minimum_size = Vector2(848.0, 56.0)
	objective_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_apply_label_style(feedback_label, 48, Color("#D8C58A"))
	feedback_label.custom_minimum_size = Vector2(848.0, 48.0)
	feedback_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_apply_label_style(pending_fragment_label, 42, Color("#CFC6AA"))
	pending_fragment_label.custom_minimum_size = Vector2(848.0, 44.0)
	pending_fragment_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	inventory_panel.anchor_left = 1.0
	inventory_panel.anchor_top = 0.5
	inventory_panel.anchor_right = 1.0
	inventory_panel.anchor_bottom = 0.5
	inventory_panel.offset_left = -296.0
	inventory_panel.offset_top = -272.0
	inventory_panel.offset_right = -24.0
	inventory_panel.offset_bottom = 272.0
	_apply_inventory_panel_style()

	inventory_margin.anchor_left = 0.0
	inventory_margin.anchor_top = 0.0
	inventory_margin.anchor_right = 1.0
	inventory_margin.anchor_bottom = 1.0
	inventory_margin.offset_left = 0.0
	inventory_margin.offset_top = 0.0
	inventory_margin.offset_right = 0.0
	inventory_margin.offset_bottom = 0.0

	inventory_margin.add_theme_constant_override("margin_left", 16)
	inventory_margin.add_theme_constant_override("margin_top", 16)
	inventory_margin.add_theme_constant_override("margin_right", 16)
	inventory_margin.add_theme_constant_override("margin_bottom", 16)

	inventory_vbox.add_theme_constant_override("separation", 8)

	_apply_label_style(inventory_title, 24, Color("#D8C58A"))
	inventory_title.text = "Inventário"
	inventory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inventory_title.custom_minimum_size = Vector2(0.0, 36.0)
	inventory_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_apply_inventory_slot_style()

	read_panel.anchor_left = 0.0
	read_panel.anchor_top = 0.0
	read_panel.anchor_right = 1.0
	read_panel.anchor_bottom = 1.0
	read_panel.offset_left = 0.0
	read_panel.offset_top = 0.0
	read_panel.offset_right = 0.0
	read_panel.offset_bottom = 0.0

	background.anchor_left = 0.0
	background.anchor_top = 0.0
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	background.offset_left = 0.0
	background.offset_top = 0.0
	background.offset_right = 0.0
	background.offset_bottom = 0.0

	bottom_bar.anchor_left = 0.0
	bottom_bar.anchor_top = 1.0
	bottom_bar.anchor_right = 1.0
	bottom_bar.anchor_bottom = 1.0
	bottom_bar.offset_left = 0.0
	bottom_bar.offset_top = -320.0
	bottom_bar.offset_right = 0.0
	bottom_bar.offset_bottom = 0.0

	read_margin.anchor_left = 0.0
	read_margin.anchor_top = 0.0
	read_margin.anchor_right = 1.0
	read_margin.anchor_bottom = 1.0
	read_margin.offset_left = 0.0
	read_margin.offset_top = 0.0
	read_margin.offset_right = 0.0
	read_margin.offset_bottom = 0.0

	read_margin.add_theme_constant_override("margin_left", 48)
	read_margin.add_theme_constant_override("margin_top", 24)
	read_margin.add_theme_constant_override("margin_right", 48)
	read_margin.add_theme_constant_override("margin_bottom", 24)

	read_vbox.add_theme_constant_override("separation", 12)

	_apply_label_style(read_title_label, 48, Color("#D8C58A"))
	read_title_label.custom_minimum_size = Vector2(0.0, 60.0)
	read_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	read_body_text.add_theme_font_size_override("normal_font_size", 28)
	read_body_text.add_theme_color_override("default_color", Color("#E8DDBD"))
	read_body_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	read_body_text.scroll_active = false
	read_body_text.fit_content = true
	read_body_text.custom_minimum_size = Vector2(0.0, 160.0)
	read_body_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	read_body_text.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_apply_label_style(close_hint_label, 24, Color("#B8B8B8"))
	close_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	close_hint_label.custom_minimum_size = Vector2(0.0, 32.0)
	close_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	_apply_endgame_style()

func _apply_inventory_slot_style() -> void:
	for slot in inventory_slots:
		slot.custom_minimum_size = Vector2(0.0, 48.0)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.add_theme_font_size_override("font_size", 20)
		slot.add_theme_color_override("font_color", Color("#E8DDBD"))
		slot.add_theme_color_override("font_disabled_color", Color("#8C846F"))

		var normal_style := StyleBoxFlat.new()
		normal_style.bg_color = Color(0.08, 0.07, 0.055, 0.72)
		normal_style.border_color = Color("#8A7650")
		normal_style.set_border_width_all(1)
		normal_style.set_corner_radius_all(4)
		normal_style.content_margin_left = 8
		normal_style.content_margin_right = 8
		normal_style.content_margin_top = 4
		normal_style.content_margin_bottom = 4

		var hover_style := normal_style.duplicate(true) as StyleBoxFlat
		hover_style.bg_color = Color(0.14, 0.12, 0.09, 0.88)
		hover_style.border_color = Color("#D8C58A")

		var pressed_style := normal_style.duplicate(true) as StyleBoxFlat
		pressed_style.bg_color = Color(0.20, 0.16, 0.10, 0.96)
		pressed_style.border_color = Color("#E8DDBD")

		var disabled_style := normal_style.duplicate(true) as StyleBoxFlat
		disabled_style.bg_color = Color(0.04, 0.04, 0.035, 0.48)
		disabled_style.border_color = Color("#4D4534")

		slot.add_theme_stylebox_override("normal", normal_style)
		slot.add_theme_stylebox_override("hover", hover_style)
		slot.add_theme_stylebox_override("pressed", pressed_style)
		slot.add_theme_stylebox_override("disabled", disabled_style)

func _connect_inventory_slots() -> void:
	for i in range(inventory_slots.size()):
		var slot: Button = inventory_slots[i]

		if not slot.pressed.is_connected(_on_inventory_slot_pressed.bind(i)):
			slot.pressed.connect(_on_inventory_slot_pressed.bind(i))


func _on_inventory_slot_pressed(slot_index: int) -> void:
	var items: Array[Dictionary] = GameState.get_inventory_items()

	if slot_index < 0 or slot_index >= items.size():
		return

	var item: Dictionary = items[slot_index]
	var item_id: StringName = item.get("id", &"")

	if item_id == &"":
		return

	GameState.select_inventory_item(item_id)


func _on_inventory_changed() -> void:
	_render_inventory()
	update_pending_fragment_label()


func _on_inventory_selection_changed(_selected_item_id: StringName) -> void:
	_render_inventory()
	update_pending_fragment_label()

func _render_inventory() -> void:
	var items: Array[Dictionary] = GameState.get_inventory_items()
	var selected_item_id: StringName = GameState.get_selected_inventory_item_id()

	for i in range(inventory_slots.size()):
		var slot: Button = inventory_slots[i]

		if i >= items.size():
			slot.text = "—"
			slot.disabled = true
			_apply_inventory_slot_visual(slot, false, false)
			continue

		var item: Dictionary = items[i]
		var item_id: StringName = item.get("id", &"")
		var item_name: String = str(item.get("name", "Item"))
		var is_selected: bool = item_id == selected_item_id

		if is_selected:
			slot.text = "> " + item_name
		else:
			slot.text = item_name

		slot.disabled = false
		_apply_inventory_slot_visual(slot, true, is_selected)

func _apply_inventory_slot_visual(slot: Button, has_item: bool, is_selected: bool) -> void:
	var normal_style := StyleBoxFlat.new()

	if not has_item:
		normal_style.bg_color = Color(0.04, 0.04, 0.035, 0.48)
		normal_style.border_color = Color("#4D4534")
	else:
		normal_style.bg_color = Color(0.08, 0.07, 0.055, 0.72)
		normal_style.border_color = Color("#8A7650")

	if is_selected:
		normal_style.bg_color = Color(0.20, 0.16, 0.10, 0.96)
		normal_style.border_color = Color("#E8DDBD")

	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(4)
	normal_style.content_margin_left = 8
	normal_style.content_margin_right = 8
	normal_style.content_margin_top = 4
	normal_style.content_margin_bottom = 4

	var hover_style := normal_style.duplicate(true) as StyleBoxFlat
	hover_style.bg_color = Color(0.14, 0.12, 0.09, 0.88)

	if has_item:
		hover_style.border_color = Color("#D8C58A")

	var pressed_style := normal_style.duplicate(true) as StyleBoxFlat
	pressed_style.bg_color = Color(0.20, 0.16, 0.10, 0.96)
	pressed_style.border_color = Color("#E8DDBD")

	slot.add_theme_stylebox_override("normal", normal_style)
	slot.add_theme_stylebox_override("hover", hover_style)
	slot.add_theme_stylebox_override("pressed", pressed_style)
	slot.add_theme_stylebox_override("disabled", normal_style)

func _configure_inventory_mouse_filter() -> void:
	inventory_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_margin.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	inventory_title.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for slot in inventory_slots:
		slot.mouse_filter = Control.MOUSE_FILTER_STOP


func _resize_read_panel_to_text() -> void:
	var viewport_height: float = get_viewport().get_visible_rect().size.y

	var title_height: float = read_title_label.get_combined_minimum_size().y
	var body_height: float = read_body_text.get_content_height()
	var hint_height: float = close_hint_label.get_combined_minimum_size().y

	var vertical_margins: float = 48.0
	var separations: float = 24.0
	var safety_padding: float = 32.0

	var desired_height: float = (
		title_height
		+ body_height
		+ hint_height
		+ vertical_margins
		+ separations
		+ safety_padding
	)

	var min_height: float = 320.0
	var max_height: float = viewport_height * 0.64

	var final_height: float = clamp(desired_height, min_height, max_height)
	final_height = _round_to_multiple_of_4(final_height)

	bottom_bar.offset_top = -final_height
	bottom_bar.offset_bottom = 0.0

	var available_body_height: float = (
		final_height
		- title_height
		- hint_height
		- vertical_margins
		- separations
		- safety_padding
	)

	available_body_height = max(160.0, available_body_height)
	available_body_height = _round_to_multiple_of_4(available_body_height)

	read_body_text.custom_minimum_size.y = available_body_height

	if desired_height > max_height:
		read_body_text.scroll_active = true
	else:
		read_body_text.scroll_active = false


func _apply_label_style(label: Label, font_size: int, color: Color) -> void:
	var settings: LabelSettings

	if label.label_settings != null:
		settings = label.label_settings.duplicate(true) as LabelSettings
	else:
		settings = LabelSettings.new()

	settings.font_size = font_size
	settings.font_color = color

	label.label_settings = settings
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _apply_inventory_panel_style() -> void:
	var panel_style := StyleBoxFlat.new()

	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.56)
	panel_style.border_color = Color("#8A7650")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)

	panel_style.content_margin_left = 0
	panel_style.content_margin_top = 0
	panel_style.content_margin_right = 0
	panel_style.content_margin_bottom = 0

	inventory_panel.add_theme_stylebox_override("panel", panel_style)

func start_endgame_sequence() -> void:
	if ending_open:
		return

	ending_open = true
	modal_open = true
	reading_open = false

	hud.visible = false
	if feedback_tween != null:
		feedback_tween.kill()
		feedback_tween = null
	read_panel.visible = false

	end_game_panel.visible = true
	end_fade_rect.modulate.a = 0.0

	end_title.visible = false
	end_subtitle.visible = false

	end_title.text = "Nunca mais!"
	end_title.modulate.a = 0.0
	end_subtitle.modulate.a = 0.0

	var tween := create_tween()

	tween.tween_property(end_fade_rect, "modulate:a", 0.86, 0.18)
	tween.tween_interval(0.10)
	tween.tween_property(end_fade_rect, "modulate:a", 0.18, 0.16)
	tween.tween_interval(0.12)
	tween.tween_property(end_fade_rect, "modulate:a", 0.94, 0.22)
	tween.tween_interval(0.14)
	tween.tween_property(end_fade_rect, "modulate:a", 0.34, 0.20)
	tween.tween_interval(0.18)
	tween.tween_property(end_fade_rect, "modulate:a", 1.0, 0.75)

	tween.tween_callback(_show_endgame_text)
	
func _show_endgame_text() -> void:
	end_title.visible = true
	end_subtitle.visible = false

	var text_tween := create_tween()
	text_tween.tween_property(end_title, "modulate:a", 1.0, 1.0)

func _apply_endgame_style() -> void:
	end_game_panel.anchor_left = 0.0
	end_game_panel.anchor_top = 0.0
	end_game_panel.anchor_right = 1.0
	end_game_panel.anchor_bottom = 1.0
	end_game_panel.offset_left = 0.0
	end_game_panel.offset_top = 0.0
	end_game_panel.offset_right = 0.0
	end_game_panel.offset_bottom = 0.0
	end_game_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	end_fade_rect.anchor_left = 0.0
	end_fade_rect.anchor_top = 0.0
	end_fade_rect.anchor_right = 1.0
	end_fade_rect.anchor_bottom = 1.0
	end_fade_rect.offset_left = 0.0
	end_fade_rect.offset_top = 0.0
	end_fade_rect.offset_right = 0.0
	end_fade_rect.offset_bottom = 0.0
	end_fade_rect.color = Color.BLACK
	end_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	end_center.anchor_left = 0.0
	end_center.anchor_top = 0.0
	end_center.anchor_right = 1.0
	end_center.anchor_bottom = 1.0
	end_center.offset_left = 0.0
	end_center.offset_top = 0.0
	end_center.offset_right = 0.0
	end_center.offset_bottom = 0.0
	end_center.mouse_filter = Control.MOUSE_FILTER_IGNORE

	end_vbox.add_theme_constant_override("separation", 18)
	end_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_vbox.custom_minimum_size = Vector2(900.0, 120.0)
	end_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	end_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	_apply_label_style(end_title, 86, Color("#D8C58A"))
	end_title.text = "Nunca mais!"
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	end_title.clip_text = false
	end_title.custom_minimum_size = Vector2(900.0, 120.0)
	end_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	end_title.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_apply_label_style(end_subtitle, 42, Color("#E8DDBD"))
	end_subtitle.text = ""
	end_subtitle.visible = false
	end_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _round_to_multiple_of_4(value: float) -> float:
	return ceil(value / 4.0) * 4.0


func _set_mouse_filter_recursive(node: Node, filter: int) -> void:
	if node is Control:
		node.mouse_filter = filter

	for child in node.get_children():
		_set_mouse_filter_recursive(child, filter)
