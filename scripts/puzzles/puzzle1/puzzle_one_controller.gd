extends Node
class_name Puzzle1Controller

signal puzzle1_solved

@export var books_controller: PuzzleBooksController
@export var clock: PuzzleClock

var books_done: bool = false
var puzzle_solved: bool = false


func _ready() -> void:
	if books_controller != null:
		books_controller.books_solved.connect(_on_books_solved)

	if clock != null:
		clock.time_changed.connect(_on_clock_time_changed)


func _on_books_solved() -> void:
	books_done = true
	_check_completion()


func _on_clock_time_changed() -> void:
	_check_completion()


func _check_completion() -> void:
	if puzzle_solved:
		return

	if books_controller == null or clock == null:
		return

	if books_done and clock.is_at_target_time():
		_solve_puzzle()


func _solve_puzzle() -> void:
	puzzle_solved = true

	clock.lock_clock()
	clock.stop_pendulum_animation()
	clock.hide_glass()
	clock.release_fragment_paper()

	puzzle1_solved.emit()
