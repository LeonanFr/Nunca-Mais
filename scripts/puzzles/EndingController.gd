extends Node
class_name EndingController

var ending_started: bool = false

func _ready() -> void:
	add_to_group("ending_controller")

func start_ending() -> void:
	if ending_started:
		return

	ending_started = true

	_lock_gameplay_input()

	AudioManager.stop_all()

	var final_duration := AudioManager.play_final_narration()

	_start_ui_endgame_sequence(final_duration)

func _lock_gameplay_input() -> void:
	if GameState.has_method("lock_gameplay_input"):
		GameState.lock_gameplay_input()

func _start_ui_endgame_sequence(final_duration: float) -> void:
	var ui := get_tree().get_first_node_in_group("ui")

	if ui == null:
		push_warning("EndingController não encontrou UI no grupo 'ui'.")
		return

	if ui.has_method("start_endgame_sequence_with_duration"):
		ui.call("start_endgame_sequence_with_duration", final_duration)
		return

	if ui.has_method("start_endgame_sequence"):
		ui.call("start_endgame_sequence")
		return

	push_warning("UI não possui função de endgame.")
