extends Node

signal fragment_collected(fragment_id: int)
signal puzzle_state_changed(new_state: int)
signal objective_changed(new_objective: String)
signal fragment_registered(fragment_id: int)
signal fragment_read(fragment_id: int)
signal inventory_changed
signal inventory_selection_changed(selected_item_id: StringName)

var gameplay_input_locked: bool = false
var puzzle_state: int = 0

var collected_fragments: Array[int] = []
var read_fragments: Array[int] = []
var registered_fragments: Array[int] = []

var inventory_items: Array[Dictionary] = []
var selected_inventory_item_id: StringName = &""

var fragments := {
	1: {
		"title": "O Estudo",
		"text": "Foi uma vez: eu refletia, à meia-noite erma e sombria,
A ler doutrinas de outro tempo em curiosíssimos manuais,
E, exausto, quase adormecido, ouvi de súbito um ruído,
Tal qual se houvesse alguém batido à minha porta, devagar.
“É alguém, fiquei a murmurar, que bate à porta, devagar;
Sim, é só isso e nada mais.”"
	},
	2: {
		"title": "Lenora",
		"text": "Ah! claramente eu o relembro! Era no gélido dezembro
E o fogo, agônico, animava o chão de sombras fantasmais.
Ansiando ver a noite finda, em vão, a ler, buscava ainda
Algum remédio à amarga, infinda, atroz saudade de Lenora
Essa, mais bela do que a aurora, a quem nos céus chamam Lenora
E nome aqui já não tem mais."
	},
	3: {
		"title": "A Porta",
		"text": "Ergui-me após e, calmo enfim, sem hesitar, falei assim:
“Perdoai, senhora, ou meu senhor, se há muito aí fora me esperais;
Mas é que estava adormecido e foi tão débil o batido,
Que eu mal podia ter ouvido alguém chamar à minha porta,
Assim de leve, em hora morta.” Escancarei então a porta:
Escuridão, e nada mais."
	},
	4: {
		"title": "A Janela",
		"text": "Com a alma em febre, eu novamente entrei no quarto e, de repente,
Mais forte, o ruído recomeça e repercute nos vitrais.
“É na janela”, penso então. “Por que agitar-me de aflição?
Conserva a calma, coração! É na janela, onde, agourento,
O vento sopra. É só do vento esse rumor surdo e agourento.
É o vento só e nada mais.”"
	},
	5: {
		"title": "O Corvo",
		"text": "Ao ver da ave austera e escura a soleníssima figura,
Desperta em mim um leve riso, a distrair-me de meus ais.
“Sem crista embora, ó Corvo antigo e singular”, então lhe digo
“Não tens pavor. Fala comigo, alma da noite, espectro torvo!”
Qual é teu nome, ó nobre Corvo, o nome teu no inferno torvo!”
E o Corvo disse: “Nunca mais.”"
	}
}

var final_fragment := {
	"title": "A Sombra Final",
	"text": "E lá ficou! Hirto, sombrio, ainda hoje o vejo, horas a fio,
Sobre o alvo busto de Minerva, inerte, sempre em meus umbrais.
No seu olhar medonho e enorme o anjo do mal, em sonhos, dorme,
E a luz da lâmpada, disforme, atira ao chão a sua sombra.
Nela, que ondula sobre a alfombra, está minha alma; e, presa à sombra,
Não há de erguer-se, ai! nunca mais!"
}

func _ready() -> void:
	objective_changed.emit(get_current_objective())

func lock_gameplay_input() -> void:
	gameplay_input_locked = true

func unlock_gameplay_input() -> void:
	gameplay_input_locked = false

func is_gameplay_input_locked() -> bool:
	return gameplay_input_locked

func has_collected_fragment(fragment_id: int) -> bool:
	return collected_fragments.has(fragment_id)

func has_registered_fragment(fragment_id: int) -> bool:
	return registered_fragments.has(fragment_id)

func has_fragment(fragment_id: int) -> bool:
	return has_registered_fragment(fragment_id)
	
func add_inventory_item(item_id: StringName, item_name: String, item_type: StringName, ref_id: int = 0) -> bool:
	if has_inventory_item(item_id):
		return false

	inventory_items.append({
		"id": item_id,
		"name": item_name,
		"type": item_type,
		"ref_id": ref_id
	})

	inventory_changed.emit()
	objective_changed.emit(get_current_objective())

	return true


func remove_inventory_item(item_id: StringName) -> bool:
	for i in range(inventory_items.size()):
		var item: Dictionary = inventory_items[i]

		if item.get("id", &"") == item_id:
			inventory_items.remove_at(i)

			if selected_inventory_item_id == item_id:
				selected_inventory_item_id = &""
				inventory_selection_changed.emit(selected_inventory_item_id)

			inventory_changed.emit()
			objective_changed.emit(get_current_objective())

			return true

	return false


func has_inventory_item(item_id: StringName) -> bool:
	for item in inventory_items:
		if item.get("id", &"") == item_id:
			return true

	return false


func get_inventory_items() -> Array[Dictionary]:
	return inventory_items.duplicate(true)


func get_inventory_item_data(item_id: StringName) -> Dictionary:
	for item in inventory_items:
		if item.get("id", &"") == item_id:
			return item

	return {}


func select_inventory_item(item_id: StringName) -> bool:
	if item_id == &"":
		clear_inventory_selection()
		return true

	if not has_inventory_item(item_id):
		return false

	if selected_inventory_item_id == item_id:
		selected_inventory_item_id = &""
	else:
		selected_inventory_item_id = item_id

	inventory_selection_changed.emit(selected_inventory_item_id)
	objective_changed.emit(get_current_objective())

	return true


func clear_inventory_selection() -> void:
	if selected_inventory_item_id == &"":
		return

	selected_inventory_item_id = &""
	inventory_selection_changed.emit(selected_inventory_item_id)
	objective_changed.emit(get_current_objective())


func get_selected_inventory_item_id() -> StringName:
	return selected_inventory_item_id


func get_selected_inventory_item_data() -> Dictionary:
	if selected_inventory_item_id == &"":
		return {}

	return get_inventory_item_data(selected_inventory_item_id)


func get_selected_fragment_id() -> int:
	if selected_inventory_item_id == &"":
		return 0

	var item: Dictionary = get_selected_inventory_item_data()

	if item.is_empty():
		return 0

	if item.get("type", &"") != &"fragment":
		return 0

	return int(item.get("ref_id", 0))


func _make_fragment_item_id(fragment_id: int) -> StringName:
	return StringName("fragment_%s" % fragment_id)

func collect_fragment(fragment_id: int) -> void:
	if not fragments.has(fragment_id):
		print("Fragmento inválido: ", fragment_id)
		return

	if has_collected_fragment(fragment_id):
		print("Fragmento já está no inventário: ", fragment_id)
		return

	if has_registered_fragment(fragment_id):
		print("Fragmento já está no livro: ", fragment_id)
		return

	collected_fragments.append(fragment_id)

	var data: Dictionary = fragments[fragment_id]
	var item_id: StringName = _make_fragment_item_id(fragment_id)

	add_inventory_item(item_id, data["title"], &"fragment", fragment_id)

	print("Fragmento coletado para o inventário: ", data["title"])
	print("Selecione o fragmento no inventário e coloque-o no livro.")

	fragment_collected.emit(fragment_id)
	objective_changed.emit(get_current_objective())

func register_fragment(fragment_id: int) -> bool:
	if not has_collected_fragment(fragment_id):
		print("Esse fragmento não está no inventário: ", fragment_id)
		return false

	if has_registered_fragment(fragment_id):
		print("Fragmento já registrado no livro: ", fragment_id)
		return false

	collected_fragments.erase(fragment_id)
	registered_fragments.append(fragment_id)

	var data: Dictionary = fragments[fragment_id]
	var item_id: StringName = _make_fragment_item_id(fragment_id)

	remove_inventory_item(item_id)

	print("Fragmento registrado no livro: ", data["title"])

	fragment_registered.emit(fragment_id)
	objective_changed.emit(get_current_objective())

	return true

func read_fragment(fragment_id: int) -> void:
	if not has_registered_fragment(fragment_id):
		print("Fragmento ainda não foi registrado no livro: ", fragment_id)
		return

	if read_fragments.has(fragment_id):
		return

	read_fragments.append(fragment_id)

	var data: Dictionary = fragments[fragment_id]
	print("Fragmento lido: ", data["title"])

	fragment_read.emit(fragment_id)
	_try_advance_after_read_fragment(fragment_id)
	objective_changed.emit(get_current_objective())

func _try_advance_after_read_fragment(fragment_id: int) -> void:
	if fragment_id == 1 and puzzle_state == 0:
		set_puzzle_state(1)
	elif fragment_id == 2 and puzzle_state == 1:
		set_puzzle_state(2)
	elif fragment_id == 3 and puzzle_state == 2:
		set_puzzle_state(3)
	elif fragment_id == 4 and puzzle_state == 3:
		set_puzzle_state(4)
	elif fragment_id == 5 and puzzle_state == 4:
		set_puzzle_state(5)

func has_pending_fragments() -> bool:
	return not collected_fragments.is_empty()


func get_pending_fragment_ids() -> Array[int]:
	return collected_fragments.duplicate()


func has_unread_registered_fragments() -> bool:
	for fragment_id in registered_fragments:
		if not read_fragments.has(fragment_id):
			return true

	return false

func set_puzzle_state(new_state: int) -> void:
	if puzzle_state == new_state:
		return

	puzzle_state = new_state

	print("Novo puzzle_state: ", puzzle_state)
	print("Objetivo atual: ", get_current_objective())

	puzzle_state_changed.emit(puzzle_state)
	objective_changed.emit(get_current_objective())

func get_current_objective() -> String:
	if has_pending_fragments():
		if get_selected_fragment_id() > 0:
			return "Coloque o fragmento no livro."

		return "Selecione um fragmento no inventário."

	if has_unread_registered_fragments():
		return "Leia o fragmento no livro."

	match puzzle_state:
		0:
			return "Veja a escrivaninha."
		1:
			return "Investigue os livros e o relógio."
		2:
			return "Investigue a lareira e o nome perdido."
		3:
			return "Escute a porta."
		4:
			return "Vá até a janela."
		5:
			return "Fala comigo, ó Corvo antigo e singular."
		_:
			return ""

func get_fragment_data(fragment_id: int) -> Dictionary:
	if not fragments.has(fragment_id):
		return {}

	return fragments[fragment_id]

func get_collected_fragment_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for fragment_id in registered_fragments:
		var data: Dictionary = get_fragment_data(fragment_id)

		if not data.is_empty():
			result.append({
				"id": fragment_id,
				"title": data["title"],
				"text": data["text"]
			})

	return result

func has_all_main_fragments() -> bool:
	return (
		has_fragment(1)
		and has_fragment(2)
		and has_fragment(3)
		and has_fragment(4)
		and has_fragment(5)
	)

func get_final_fragment_data() -> Dictionary:
	return final_fragment

func can_use_puzzle_1() -> bool:
	return puzzle_state == 1

func can_use_puzzle_2() -> bool:
	return puzzle_state == 2

func can_use_puzzle_3() -> bool:
	return puzzle_state == 3

func can_use_puzzle_4() -> bool:
	return puzzle_state == 4

func can_use_final_assembly() -> bool:
	return puzzle_state == 5
