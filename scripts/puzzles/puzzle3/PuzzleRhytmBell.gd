extends Node3D
class_name PuzzleRhythmBell

@export var rhythm_value: int = 1
@export var controller: Node

@export var animation_player: AnimationPlayer
@export var animation_name: StringName = &"Animation"

func _ready() -> void:
	if animation_player == null:
		animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer

func interact(_camera_rig = null) -> void:
	_play_animation()

	if controller == null:
		push_warning("PuzzleRhythmBell sem controller configurado.")
		return

	if not controller.has_method("submit_rhythm_value"):
		push_warning("Controller do sino não possui submit_rhythm_value().")
		return

	controller.submit_rhythm_value(rhythm_value)

func _play_animation() -> void:
	if animation_player == null:
		push_warning("Sino sem AnimationPlayer configurado.")
		return

	if not animation_player.has_animation(animation_name):
		push_warning("Animação do sino não encontrada: %s" % animation_name)
		return

	animation_player.stop()
	animation_player.play(animation_name)
