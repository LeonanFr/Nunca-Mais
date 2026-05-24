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
	get_tree().call_group("ui", "start_endgame_sequence")

func _lock_gameplay_input() -> void:
	if GameState.has_method("lock_gameplay_input"):
		GameState.lock_gameplay_input()
