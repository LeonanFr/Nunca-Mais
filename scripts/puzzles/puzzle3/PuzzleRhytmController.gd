extends Node
class_name PuzzleRhythmController

signal puzzle3_solved

enum RhythmSoundType {
	BELL,
	DOOR_KNOCK
}

@export var required_state: int = 3
@export var target_sequence: Array[int] = [1, 3, 3, 2, 1]

@export_group("Som")
@export var rhythm_sound_type: RhythmSoundType = RhythmSoundType.BELL

@export_group("Referências")
@export var fragment_paper: Node3D
@export var door_group: StringName = &"puzzle3_door"

var door: Node
var current_sequence: Array[int] = []
var solved: bool = false

func _ready() -> void:
	door = get_tree().get_first_node_in_group(door_group)

	if door != null and door.has_method("set_fragment_paper"):
		door.set_fragment_paper(fragment_paper)

	if GameState.puzzle_state > required_state:
		solved = true

	_setup_fragment()
	_connect_fragment_signal()

func submit_rhythm_value(value: int) -> void:
	if solved:
		_show_feedback("O quarto já reconheceu o ritmo.")
		return

	if GameState.puzzle_state < required_state:
		_show_feedback("Silêncio e nada mais.")
		return

	if GameState.puzzle_state > required_state:
		_show_feedback("A porta já cedeu ao ritmo.")
		return

	AudioManager.play_bell_count(value)

	current_sequence.append(value)

	_show_feedback(_get_sequence_feedback())

	if current_sequence.size() >= target_sequence.size():
		_validate_sequence()

func _play_rhythm_sound(value: int) -> void:
	match rhythm_sound_type:
		RhythmSoundType.BELL:
			AudioManager.play_bell_count(value)
		RhythmSoundType.DOOR_KNOCK:
			AudioManager.play_door_knock_count(value)

func _validate_sequence() -> void:
	if current_sequence == target_sequence:
		_solve()
		return

	current_sequence.clear()
	_show_feedback("O quarto não reconheceu o ritmo.")

func _solve() -> void:
	if solved:
		return

	solved = true
	current_sequence.clear()

	_show_feedback("A porta cede, mas não oferece saída.")

	if door != null and door.has_method("open_after_rhythm_puzzle"):
		door.open_after_rhythm_puzzle()
	else:
		push_warning("Porta do Puzzle 3 não encontrada ou sem open_after_rhythm_puzzle().")

	_release_fragment()

	puzzle3_solved.emit()

func _setup_fragment() -> void:
	if fragment_paper == null:
		return

	if solved:
		_release_fragment()
		return

	if fragment_paper.has_method("set_available"):
		fragment_paper.set_available(false)

func _release_fragment() -> void:
	if fragment_paper == null:
		push_warning("Puzzle3RhythmController sem fragment_paper configurado.")
		return

	if fragment_paper.has_method("set_available"):
		fragment_paper.set_available(true)

func _connect_fragment_signal() -> void:
	if fragment_paper == null:
		return

	if not fragment_paper.has_signal("fragment_collected"):
		return

	if not fragment_paper.fragment_collected.is_connected(_on_fragment_collected):
		fragment_paper.fragment_collected.connect(_on_fragment_collected)

func _on_fragment_collected(collected_fragment_id: int) -> void:
	if collected_fragment_id != 4:
		return

	if door != null and door.has_method("close_after_fragment_collected"):
		door.close_after_fragment_collected()

func _get_sequence_feedback() -> String:
	match current_sequence.size():
		1:
			return "Toc..."
		2:
			return "Toc... toc-toc-toc..."
		3:
			return "Toc... toc-toc-toc... toc-toc-toc..."
		4:
			return "Toc... toc-toc-toc... toc-toc-toc... toc-toc..."
		5:
			return "Toc... toc-toc-toc... toc-toc-toc... toc-toc... toc..."
		_:
			return "O som se perde na madeira."

func _show_feedback(text: String) -> void:
	get_tree().call_group("ui", "show_feedback", text)
