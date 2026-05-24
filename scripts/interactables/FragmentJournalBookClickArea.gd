extends Area3D

@export var focus_id: StringName = &"book"
@export var is_enabled: bool = true


func can_interact(camera_rig: Node) -> bool:
	if not is_enabled:
		return false

	if focus_id == &"":
		return false

	if camera_rig == null:
		return false

	if not camera_rig.has_method("get_current_focus_id"):
		return false

	var current_focus_id: StringName = camera_rig.call("get_current_focus_id") as StringName

	# Fora do foco do livro: clicar serve para focar.
	if current_focus_id != focus_id:
		if not camera_rig.has_method("can_focus_id"):
			return false

		return camera_rig.call("can_focus_id", focus_id)

	# Dentro do foco do livro:
	# a hitbox grande só deve funcionar se tiver fragmento pendente.
	# Se não tiver, ela não intercepta o clique dos papeizinhos.
	return GameState.has_pending_fragments()


func interact(camera_rig: Node) -> void:
	if not can_interact(camera_rig):
		return

	var current_focus_id: StringName = camera_rig.call("get_current_focus_id") as StringName

	# Primeiro clique: entra no foco do livro.
	if current_focus_id != focus_id:
		if camera_rig.has_method("try_focus"):
			camera_rig.call("try_focus", focus_id)
		return

	# Já está no foco do livro: registra fragmento pendente.
	var book: Node = _get_book()

	if book != null and book.has_method("interact"):
		book.call("interact", camera_rig)


func _get_book() -> Node:
	var current_node: Node = get_parent()

	while current_node != null:
		if current_node is FragmentJournalBook:
			return current_node

		current_node = current_node.get_parent()

	return null
