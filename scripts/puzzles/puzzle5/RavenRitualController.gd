extends Node
class_name RavenRitualController

signal ritual_completed

enum RitualMode {
	CHOOSING,
	RAVEN_RESPONSE
}

@export var required_state: int = 5
@export var panel: Control

var background: ColorRect
var bottom_bar: Control
var margin: MarginContainer
var vbox: VBoxContainer
var title_label: Label
var prompt_label: Label
var options_row: HBoxContainer
var option_buttons: Array[Button] = []

var current_round: int = 0
var is_open: bool = false
var completed: bool = false
var mode: RitualMode = RitualMode.CHOOSING

var rounds: Array[Dictionary] = [
	{
		"prompt": "O corvo inclina a cabeça. A noite espera a pergunta certa.",
		"options": [
			"Qual é a tua sina escura, ó monstro atroz de catadura!",
			"Donde vieste, alado espectro, vulto cruel de pranto infesto!",
			"Qual é teu nome, ó nobre Corvo, o nome teu no inferno torvo!"
		],
		"correct": 2
	},
	{
		"prompt": "A ave permanece imóvel sobre o busto. O quarto parece lembrar.",
		"options": [
			"Como a esperança, ao vir a aurora, ele também há de ir-se embora.",
			"Como o fantasma, ao fim da noite, ele também foge ao açoite.",
			"Como a neblina, ao sol raiando, ele também irá minguando."
		],
		"correct": 0
	},
	{
		"prompt": "A lembrança de Lenora pesa sobre a sala.",
		"options": [
			"Bebe o veneno. Bebe-o, então! Sufoque a dor no coração!",
			"Sorve-o nepentes. Sorve-o, agora! Esquece, olvida essa Lenora!",
			"Toma do cálice. Toma-o, enfim! Apaga a chama triste em mim!"
		],
		"correct": 1
	},
	{
		"prompt": "A pergunta se torna súplica.",
		"options": [
			"Haverá luz no fim do pranto? Responde-me, por piedade!",
			"Resta um consolo na amargura? Confessa-me, com claridade!",
			"Existe um bálsamo em Galaad? Imploro! Dize-mo, em verdade!"
		],
		"correct": 2
	},
	{
		"prompt": "Resta apenas a última pergunta.",
		"options": [
			"Verá a deusa fulgurante a quem nos céus chamam Lenora!",
			"Terá nos braços novamente a flor que o tempo já devora!",
			"Achará paz no fim do abismo, longe da dor que o apavora!"
		],
		"correct": 0
	}
]

func _ready() -> void:
	add_to_group("raven_ritual")
	if panel != null:
		panel.visible = false
	call_deferred("_late_setup_ui")

func _late_setup_ui() -> void:
	_cache_ui_nodes()
	_apply_visual_style()
	_configure_mouse_filter()
	_connect_option_buttons()

func start_ritual() -> void:
	if completed:
		_show_feedback("Nunca mais.")
		return
	if GameState.puzzle_state < required_state:
		_show_feedback("Pus-me a inquirir (pois, para mim, visava a algum secreto fim) que pretendia o antigo Corvo.")
		return
	if GameState.puzzle_state > required_state:
		_show_feedback("Nunca mais.")
		return
	current_round = 0
	is_open = true
	mode = RitualMode.CHOOSING
	if panel != null:
		panel.visible = true
	_update_choice_ui()
	_set_world_input_blocked(true)

func _on_option_pressed(option_index: int) -> void:
	if not is_open:
		return
	if mode == RitualMode.RAVEN_RESPONSE:
		_advance_after_raven_response()
		return
	if current_round < 0 or current_round >= rounds.size():
		return
	var round_data: Dictionary = rounds[current_round]
	var correct_index: int = int(round_data["correct"])
	if option_index != correct_index:
		_reset_after_error()
		return
	_show_raven_response()

func _show_raven_response() -> void:
	AudioManager.play_raven()

	mode = RitualMode.RAVEN_RESPONSE

	if title_label != null:
		title_label.text = "Corvo:"

	if prompt_label != null:
		prompt_label.text = "Nunca mais."

	for i in range(option_buttons.size()):
		var button: Button = option_buttons[i]

		if button == null:
			continue

		if i == 0:
			button.visible = true
			button.disabled = false
			button.text = "Continuar"
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			button.visible = false

func _advance_after_raven_response() -> void:
	current_round += 1
	if current_round >= rounds.size():
		_complete_ritual()
		return
	mode = RitualMode.CHOOSING
	_update_choice_ui()

func _reset_after_error() -> void:
	AudioManager.play_raven()

	current_round = 0
	is_open = false
	mode = RitualMode.CHOOSING

	if panel != null:
		panel.visible = false

	_set_world_input_blocked(false)
	_show_feedback("A ave rejeita a pergunta.")

func _complete_ritual() -> void:
	completed = true
	is_open = false
	mode = RitualMode.CHOOSING

	if panel != null:
		panel.visible = false

	_set_world_input_blocked(false)

	if GameState.has_method("set_puzzle_state"):
		GameState.set_puzzle_state(6)
	else:
		GameState.puzzle_state = 6

	get_tree().call_group("ending_controller", "start_ending")

	ritual_completed.emit()

func _update_choice_ui() -> void:
	if current_round < 0 or current_round >= rounds.size():
		return
	var round_data: Dictionary = rounds[current_round]
	if title_label != null:
		title_label.text = "O Corvo — pergunta %d/%d" % [current_round + 1, rounds.size()]
	if prompt_label != null:
		prompt_label.text = str(round_data["prompt"])
	var options: Array = round_data["options"]
	for i in range(option_buttons.size()):
		var button: Button = option_buttons[i]
		if button == null:
			continue
		if i < options.size():
			button.visible = true
			button.disabled = false
			button.text = str(options[i])
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			button.visible = false

func _cache_ui_nodes() -> void:
	if panel == null:
		push_warning("RavenRitualController sem panel configurado.")
		return
	background = panel.find_child("Background", true, false) as ColorRect
	bottom_bar = panel.find_child("BottomBar", true, false) as Control
	margin = panel.find_child("Margin", true, false) as MarginContainer
	vbox = panel.find_child("VBox", true, false) as VBoxContainer
	title_label = panel.find_child("TitleLabel", true, false) as Label
	prompt_label = panel.find_child("PromptLabel", true, false) as Label
	options_row = panel.find_child("OptionsRow", true, false) as HBoxContainer
	option_buttons.clear()
	var button_1: Button = panel.find_child("OptionButton1", true, false) as Button
	var button_2: Button = panel.find_child("OptionButton2", true, false) as Button
	var button_3: Button = panel.find_child("OptionButton3", true, false) as Button
	option_buttons.append(button_1)
	option_buttons.append(button_2)
	option_buttons.append(button_3)

func _apply_visual_style() -> void:
	if panel != null:
		panel.anchor_left = 0.0
		panel.anchor_top = 0.0
		panel.anchor_right = 1.0
		panel.anchor_bottom = 1.0
		panel.offset_left = 0.0
		panel.offset_top = 0.0
		panel.offset_right = 0.0
		panel.offset_bottom = 0.0
	if background != null:
		background.anchor_left = 0.0
		background.anchor_top = 0.0
		background.anchor_right = 1.0
		background.anchor_bottom = 1.0
		background.offset_left = 0.0
		background.offset_top = 0.0
		background.offset_right = 0.0
		background.offset_bottom = 0.0
		background.color = Color(0.0, 0.0, 0.0, 0.32)
	if bottom_bar != null:
		bottom_bar.anchor_left = 0.0
		bottom_bar.anchor_top = 1.0
		bottom_bar.anchor_right = 1.0
		bottom_bar.anchor_bottom = 1.0
		bottom_bar.offset_left = 0.0
		bottom_bar.offset_top = -380.0
		bottom_bar.offset_right = 0.0
		bottom_bar.offset_bottom = 0.0
		_apply_bottom_bar_style()
	if margin != null:
		margin.anchor_left = 0.0
		margin.anchor_top = 0.0
		margin.anchor_right = 1.0
		margin.anchor_bottom = 1.0
		margin.offset_left = 0.0
		margin.offset_top = 0.0
		margin.offset_right = 0.0
		margin.offset_bottom = 0.0
		margin.add_theme_constant_override("margin_left", 48)
		margin.add_theme_constant_override("margin_top", 24)
		margin.add_theme_constant_override("margin_right", 48)
		margin.add_theme_constant_override("margin_bottom", 24)
	if vbox != null:
		vbox.add_theme_constant_override("separation", 16)
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if options_row != null:
		options_row.add_theme_constant_override("separation", 18)
		options_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		options_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if title_label != null:
		_apply_label_style(title_label, 46, Color("#D8C58A"))
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title_label.custom_minimum_size = Vector2(0.0, 56.0)
		title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if prompt_label != null:
		_apply_label_style(prompt_label, 30, Color("#E8DDBD"))
		prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		prompt_label.custom_minimum_size = Vector2(0.0, 72.0)
		prompt_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for button in option_buttons:
		if button != null:
			_apply_option_button_style(button)

func _configure_mouse_filter() -> void:
	if panel != null:
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if background != null:
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bottom_bar != null:
		bottom_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	if margin != null:
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if vbox != null:
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if options_row != null:
		options_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for button in option_buttons:
		if button != null:
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			button.focus_mode = Control.FOCUS_NONE

func _connect_option_buttons() -> void:
	for i in range(option_buttons.size()):
		var button: Button = option_buttons[i]
		if button == null:
			continue
		if not button.pressed.is_connected(_on_option_pressed.bind(i)):
			button.pressed.connect(_on_option_pressed.bind(i))

func _apply_bottom_bar_style() -> void:
	if bottom_bar == null:
		return
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.0, 0.0, 0.0, 0.74)
	panel_style.border_color = Color("#8A7650")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(0)
	panel_style.content_margin_left = 0
	panel_style.content_margin_top = 0
	panel_style.content_margin_right = 0
	panel_style.content_margin_bottom = 0
	if bottom_bar is PanelContainer:
		var panel_container := bottom_bar as PanelContainer
		panel_container.add_theme_stylebox_override("panel", panel_style)

func _apply_option_button_style(button: Button) -> void:
	button.custom_minimum_size = Vector2(0.0, 150.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color("#E8DDBD"))
	button.add_theme_color_override("font_hover_color", Color("#FFF2C7"))
	button.add_theme_color_override("font_pressed_color", Color("#FFFFFF"))
	button.add_theme_color_override("font_disabled_color", Color("#8C846F"))
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.08, 0.07, 0.055, 0.88)
	normal_style.border_color = Color("#8A7650")
	normal_style.set_border_width_all(2)
	normal_style.set_corner_radius_all(8)
	normal_style.content_margin_left = 18
	normal_style.content_margin_right = 18
	normal_style.content_margin_top = 12
	normal_style.content_margin_bottom = 12
	var hover_style := normal_style.duplicate(true) as StyleBoxFlat
	hover_style.bg_color = Color(0.14, 0.12, 0.09, 0.96)
	hover_style.border_color = Color("#D8C58A")
	var pressed_style := normal_style.duplicate(true) as StyleBoxFlat
	pressed_style.bg_color = Color(0.20, 0.16, 0.10, 1.0)
	pressed_style.border_color = Color("#E8DDBD")
	var disabled_style := normal_style.duplicate(true) as StyleBoxFlat
	disabled_style.bg_color = Color(0.04, 0.04, 0.035, 0.58)
	disabled_style.border_color = Color("#4D4534")
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("disabled", disabled_style)

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

func _set_world_input_blocked(value: bool) -> void:
	var ui := get_tree().get_first_node_in_group("ui")
	if ui != null and ui.has_method("set_modal_open"):
		ui.call("set_modal_open", value)

func _show_feedback(text: String) -> void:
	get_tree().call_group("ui", "show_feedback", text)
