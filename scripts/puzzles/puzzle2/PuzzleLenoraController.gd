extends Node3D
class_name PuzzleLenoraController

signal puzzle2_solved

@export var plates: Array[LenoraPlate] = []
@export var fragment_paper: Node3D

@export var required_state: int = 2
@export var target_word: String = "LENORA"

var solved: bool = false

func _ready() -> void:
	_setup_plates()

	if GameState.puzzle_state > required_state:
		solved = true
		_lock_all_plates()

	call_deferred("_setup_fragment")

func try_advance_plate(plate: LenoraPlate, direction: int = 1) -> void:
	if solved:
		_show_feedback("Nome aqui já não tem mais.")
		return

	if GameState.puzzle_state < required_state:
		_show_feedback("Só um nome ouvi (quase em segredo eu o dizia) e foi...")
		return

	if GameState.puzzle_state > required_state:
		_show_feedback("Verei de novo a deusa fulgurante a quem nos céus chamam Lenora?")
		return

	plate.advance_letter(direction)
	_validate_word()

func _setup_plates() -> void:
	for plate in plates:
		if plate == null:
			continue

		plate.controller = self
		plate.set_locked(false)

func _setup_fragment() -> void:
	if fragment_paper == null:
		return

	if solved:
		_release_fragment()
		return

	if fragment_paper.has_method("set_available"):
		fragment_paper.set_available(false)

func _validate_word() -> void:
	var current_word := ""

	for plate in plates:
		if plate == null:
			return

		current_word += plate.get_letter()

	if current_word == target_word:
		_solve()
	else:
		_show_feedback("O nome ainda não voltou inteiro.")

func _solve() -> void:
	if solved:
		return

	solved = true

	_lock_all_plates()
	_release_fragment()

	_show_feedback("A moldura reconhece o nome perdido.")

	puzzle2_solved.emit()

func _lock_all_plates() -> void:
	for plate in plates:
		if plate != null:
			plate.set_locked(true)

func _release_fragment() -> void:
	if fragment_paper == null:
		push_warning("PuzzleLenoraController sem fragment_paper configurado.")
		return

	if fragment_paper.has_method("set_available"):
		fragment_paper.set_available(true)

func is_solved_or_past_state() -> bool:
	return solved or GameState.puzzle_state > required_state

func interact_frame() -> void:
	if is_solved_or_past_state():
		_show_feedback("Essa, mais bela do que a aurora, a quem nos céus chamam Lenora!")
		return

	_show_feedback("Há uma ausência na moldura. Algo foi arrancado dela.")

func _show_feedback(text: String) -> void:
	get_tree().call_group("ui", "show_feedback", text)
