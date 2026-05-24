extends Node3D
class_name PuzzleBooksController
signal books_solved

@export var max_correct_positions_on_shuffle: int = 2

var is_solved: bool = false
@export var books: Array[PuzzleBook] = []
@export var slots: Array[Marker3D] = []

@export var shuffle_on_start: bool = true
@export var move_duration: float = 0.42

# Ajusta isso no Inspector se os livros estiverem atravessando a estante.
# É um deslocamento global usado na animação de troca.
@export var swap_out_offset: Vector3 = Vector3(0.0, 0.08, 0.08)

@export var correct_order: Array[StringName] = [
	&"meia_noite",
	&"manuais",
	&"ruido",
	&"porta",
	&"devagar",
	&"nada_mais"
]

var selected_book: PuzzleBook = null
var is_animating: bool = false

var book_to_slot: Dictionary = {}
var slot_to_book: Array[PuzzleBook] = []

func _ready() -> void:
	_validate_setup()
	_prepare_slot_array()
	_place_books_on_start()

func handle_book_clicked(book: PuzzleBook) -> void:
	if is_solved:
		_show_feedback("Doutrinas de outro tempo... Há quanto tempo não as leio.")
		return

	if not GameState.can_use_puzzle_1():
		_show_feedback("Ainda não compreendo estes livros.")
		return

	if is_animating:
		return

	if book == null:
		return

	if not book_to_slot.has(book):
		push_warning("Livro clicado não está registrado no puzzle: %s" % book.name)
		return

	if selected_book == null:
		_select_book(book)
		return

	if selected_book == book:
		_clear_selection()
		return

	var first_book: PuzzleBook = selected_book
	var second_book: PuzzleBook = book

	_clear_selection()
	await _swap_books(first_book, second_book)

func get_current_order() -> Array[StringName]:
	var order: Array[StringName] = []

	for book in slot_to_book:
		if book == null:
			order.append(&"")
		else:
			order.append(book.book_id)

	return order

func is_correct_order() -> bool:
	var current_order: Array[StringName] = get_current_order()

	if current_order.size() != correct_order.size():
		return false

	for i in range(correct_order.size()):
		if current_order[i] != correct_order[i]:
			return false

	return true

func _select_book(book: PuzzleBook) -> void:
	selected_book = book
	selected_book.set_selected(true)

func _clear_selection() -> void:
	if selected_book != null:
		selected_book.set_selected(false)

	selected_book = null

func _swap_books(book_a: PuzzleBook, book_b: PuzzleBook) -> void:
	is_animating = true

	var slot_a: int = int(book_to_slot[book_a])
	var slot_b: int = int(book_to_slot[book_b])

	book_to_slot[book_a] = slot_b
	book_to_slot[book_b] = slot_a

	slot_to_book[slot_a] = book_b
	slot_to_book[slot_b] = book_a

	var slot_a_position: Vector3 = slots[slot_a].global_position
	var slot_b_position: Vector3 = slots[slot_b].global_position

	var slot_a_rotation: Vector3 = slots[slot_a].global_rotation
	var slot_b_rotation: Vector3 = slots[slot_b].global_rotation

	await _animate_two_books(
		book_a,
		slot_a_position + swap_out_offset,
		book_a.global_rotation,
		book_b,
		slot_b_position + swap_out_offset,
		book_b.global_rotation,
		move_duration * 0.25
	)

	await _animate_two_books(
		book_a,
		slot_b_position + swap_out_offset,
		slot_b_rotation,
		book_b,
		slot_a_position + swap_out_offset,
		slot_a_rotation,
		move_duration * 0.45
	)

	await _animate_two_books(
		book_a,
		slot_b_position,
		slot_b_rotation,
		book_b,
		slot_a_position,
		slot_a_rotation,
		move_duration * 0.30
	)

	book_a.global_position = slot_b_position
	book_a.global_rotation = slot_b_rotation

	book_b.global_position = slot_a_position
	book_b.global_rotation = slot_a_rotation

	if is_correct_order():
		_solve_books_puzzle()

	is_animating = false

func _solve_books_puzzle() -> void:
	if is_solved:
		return

	is_solved = true
	_clear_selection()

	for book in books:
		if book != null:
			book.set_selected(false)

	books_solved.emit()

func _animate_two_books(
	book_a: PuzzleBook,
	position_a: Vector3,
	rotation_a: Vector3,
	book_b: PuzzleBook,
	position_b: Vector3,
	rotation_b: Vector3,
	duration: float
) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(book_a, "global_position", position_a, duration)
	tween.tween_property(book_a, "global_rotation", rotation_a, duration)

	tween.tween_property(book_b, "global_position", position_b, duration)
	tween.tween_property(book_b, "global_rotation", rotation_b, duration)

	await tween.finished

func _prepare_slot_array() -> void:
	slot_to_book.clear()
	slot_to_book.resize(slots.size())

func _place_books_on_start() -> void:
	var start_books: Array[PuzzleBook] = []

	for book in books:
		if book != null:
			start_books.append(book)

	if shuffle_on_start:
		start_books = _get_valid_shuffled_books(start_books)

	var amount: int = min(start_books.size(), slots.size())

	for i in range(amount):
		var book: PuzzleBook = start_books[i]
		_place_book_in_slot(book, i)

func _get_valid_shuffled_books(source_books: Array[PuzzleBook]) -> Array[PuzzleBook]:
	var shuffled_books: Array[PuzzleBook] = source_books.duplicate()
	var max_attempts: int = 80

	for attempt in range(max_attempts):
		shuffled_books.shuffle()

		if not _book_array_matches_correct_order(shuffled_books) and _count_correct_positions(shuffled_books) <= max_correct_positions_on_shuffle:
			return shuffled_books

	shuffled_books.reverse()

	return shuffled_books

func _count_correct_positions(book_array: Array[PuzzleBook]) -> int:
	var count: int = 0
	var amount: int = min(book_array.size(), correct_order.size())

	for i in range(amount):
		var book: PuzzleBook = book_array[i]

		if book != null and book.book_id == correct_order[i]:
			count += 1

	return count

func _place_book_in_slot(book: PuzzleBook, slot_index: int) -> void:
	if book == null:
		return

	if slot_index < 0 or slot_index >= slots.size():
		return

	var slot: Marker3D = slots[slot_index]

	if slot == null:
		return

	book.global_position = slot.global_position
	book.global_rotation = slot.global_rotation

	book_to_slot[book] = slot_index
	slot_to_book[slot_index] = book

func _book_array_matches_correct_order(book_array: Array[PuzzleBook]) -> bool:
	if book_array.size() != correct_order.size():
		return false

	for i in range(correct_order.size()):
		var book: PuzzleBook = book_array[i]

		if book == null:
			return false

		if book.book_id != correct_order[i]:
			return false

	return true

func _validate_setup() -> void:
	if books.is_empty():
		push_warning("PuzzleBooksController sem livros configurados.")

	if slots.is_empty():
		push_warning("PuzzleBooksController sem slots configurados.")

	if books.size() != slots.size():
		push_warning("Quantidade de livros diferente da quantidade de slots.")

func _show_feedback(text: String) -> void:
	get_tree().call_group("ui", "show_feedback", text)
