extends Node3D

@export var fragment_id: int = 0
@export var title_label: Label3D

var journal_book: Node = null


func _ready() -> void:
	_update_visual()


func setup(new_fragment_id: int, new_journal_book: Node) -> void:
	fragment_id = new_fragment_id
	journal_book = new_journal_book
	_update_visual()


func interact(camera_rig = null) -> void:
	if journal_book == null:
		return

	if journal_book.has_method("show_fragment"):
		journal_book.call("show_fragment", fragment_id, camera_rig)


func _update_visual() -> void:
	if title_label == null:
		return

	var title := "Fragmento"

	if fragment_id > 0:
		var data: Dictionary = GameState.get_fragment_data(fragment_id)

		if not data.is_empty():
			title = data["title"]

	title_label.text = title
