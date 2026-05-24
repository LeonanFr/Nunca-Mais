extends Node3D
class_name FragmentJournalBook

@export var required_focus_id: StringName = &"book"

@export var journal_fragment_item_scene: PackedScene
@export var fragment_slots: Array[Marker3D] = []

var fragment_items_by_id: Dictionary = {}

func _ready() -> void:
	_restore_registered_fragments()

func interact(camera_rig = null) -> void:
	if not _is_focus_allowed(camera_rig):
		_show_feedback("Abra o livro para registrar os fragmentos.")
		return

	var selected_fragment_id: int = GameState.get_selected_fragment_id()

	if selected_fragment_id <= 0:
		if GameState.has_pending_fragments():
			_show_feedback("Selecione um fragmento no inventário.")
			return

		_show_feedback("Clique em um fragmento registrado para reler.")
		return

	if GameState.register_fragment(selected_fragment_id):
		_add_fragment_to_slot(selected_fragment_id)

		_show_feedback("Fragmento registrado no livro.")
		show_fragment(selected_fragment_id, camera_rig)
		return

	_show_feedback("Este fragmento não pode ser colocado aqui.")

func show_fragment(fragment_id: int, camera_rig = null) -> void:
	if not _is_focus_allowed(camera_rig):
		_show_feedback("Abra o livro para ler os fragmentos.")
		return

	var data: Dictionary = GameState.get_fragment_data(fragment_id)

	if data.is_empty():
		push_warning("Fragmento inexistente: %s" % fragment_id)
		return

	print("")
	print("=== ", data["title"], " ===")
	print(data["text"])
	print("")

	get_tree().call_group("ui", "show_fragment", data["title"], data["text"])

	GameState.read_fragment(fragment_id)

func _add_fragment_to_slot(fragment_id: int) -> void:
	if fragment_items_by_id.has(fragment_id):
		return

	if journal_fragment_item_scene == null:
		push_warning("FragmentJournalBook sem journal_fragment_item_scene configurada.")
		return

	var slot_index: int = fragment_id - 1

	if slot_index < 0 or slot_index >= fragment_slots.size():
		push_warning("Sem slot configurado para fragment_id: %s" % fragment_id)
		return

	var slot: Marker3D = fragment_slots[slot_index]

	if slot == null:
		push_warning("Slot nulo para fragment_id: %s" % fragment_id)
		return

	var item := journal_fragment_item_scene.instantiate() as Node3D

	if item == null:
		push_warning("A cena do fragmento do journal precisa ter Node3D no root.")
		return

	if not item.has_method("setup"):
		push_warning("A cena do fragmento do journal precisa ter método setup().")
		item.queue_free()
		return

	add_child(item)

	item.global_transform = slot.global_transform
	item.call("setup", fragment_id, self)

	fragment_items_by_id[fragment_id] = item

func _restore_registered_fragments() -> void:
	for fragment_id in GameState.registered_fragments:
		_add_fragment_to_slot(fragment_id)

func _is_focus_allowed(camera_rig) -> bool:
	if required_focus_id == &"":
		return true

	if camera_rig == null:
		return false

	if not camera_rig.has_method("get_current_focus_id"):
		return false

	return camera_rig.get_current_focus_id() == required_focus_id

func _show_feedback(text: String) -> void:
	get_tree().call_group("ui", "show_feedback", text)
