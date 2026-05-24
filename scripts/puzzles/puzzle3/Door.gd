extends Node3D
class_name PuzzleDoor

@export var animation_player: AnimationPlayer
@export var open_animation_name: StringName = &"Armature|Open"

@export var focus_clickable: FocusClickable
@export var closed_focus_id: StringName = &"door"
@export var open_focus_id: StringName = &"door_open"

var fragment_paper: Node = null
var opened: bool = false
var puzzle_solved: bool = false

func _ready() -> void:
	add_to_group("puzzle_door")

	if animation_player == null:
		animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer

	if focus_clickable == null:
		focus_clickable = find_child("ClickArea", true, false) as FocusClickable

	if focus_clickable != null:
		focus_clickable.focus_id = closed_focus_id
	

func set_fragment_paper(paper: Node) -> void:
	fragment_paper = paper

func has_available_fragment_paper() -> bool:
	if fragment_paper == null:
		return false

	if not is_instance_valid(fragment_paper):
		return false

	if not fragment_paper.has_method("is_available"):
		return false

	return fragment_paper.call("is_available")

func open_after_rhythm_puzzle() -> void:
	if opened:
		return

	puzzle_solved = true
	opened = true

	_play_open_animation()
	_switch_to_open_focus()


func close_after_fragment_collected() -> void:
	if not opened:
		return

	opened = false

	_play_close_animation()
	_switch_to_closed_focus()

func should_show_darkness_feedback(camera_rig: Node) -> bool:
	if not puzzle_solved:
		return false

	if not opened:
		return false

	if camera_rig == null:
		return false

	if not camera_rig.has_method("get_current_focus_id"):
		return false

	return camera_rig.get_current_focus_id() == open_focus_id

func show_darkness_feedback() -> void:
	_show_feedback("Escuridão, e nada mais.")

func interact_closed_door() -> void:
	if GameState.puzzle_state == 3 and not puzzle_solved:
		_show_feedback("Perdoai, senhora, ou meu senhor, se há muito aí fora me esperais;")
		return

	if puzzle_solved:
		_show_feedback("Escuridão, e nada mais.")
		return

	_show_feedback("Ouvi de súbito um ruído.")

func _play_open_animation() -> void:
	if animation_player == null:
		push_warning("PuzzleDoor sem AnimationPlayer configurado.")
		return

	if not animation_player.has_animation(open_animation_name):
		push_warning("Animação da porta não encontrada: %s" % open_animation_name)
		return

	animation_player.play(open_animation_name)

func _play_close_animation() -> void:
	if animation_player == null:
		push_warning("PuzzleDoor sem AnimationPlayer configurado.")
		return

	if not animation_player.has_animation(open_animation_name):
		push_warning("Animação da porta não encontrada: %s" % open_animation_name)
		return

	animation_player.play_backwards(open_animation_name)

func _switch_to_open_focus() -> void:
	if focus_clickable == null:
		push_warning("Puzzle3Door sem FocusClickable configurado.")
		return

	focus_clickable.focus_id = open_focus_id

func _switch_to_closed_focus() -> void:
	if focus_clickable == null:
		push_warning("Puzzle3Door sem FocusClickable configurado.")
		return

	focus_clickable.focus_id = closed_focus_id

func _show_feedback(text: String) -> void:
	get_tree().call_group("ui", "show_feedback", text)
