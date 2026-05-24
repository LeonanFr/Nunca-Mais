extends Node3D
class_name RavenController

@export var animation_player: AnimationPlayer

@export var window_idle_animation: StringName = &"window_look"
@export var fly_animation: StringName = &"fly_to_bust"
@export var bust_idle_animation: StringName = &"bust_look"

var is_on_bust: bool = false

func _ready() -> void:
	if animation_player == null:
		animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer

func apply_marker_transform(marker: Node3D) -> void:
	if marker == null:
		return
	global_position = marker.global_position
	global_rotation = marker.global_rotation

func setup_at_window(window_marker: Node3D) -> void:
	apply_marker_transform(window_marker)
	visible = true
	is_on_bust = false
	play_window_idle()

func setup_at_bust(bust_marker: Node3D) -> void:
	apply_marker_transform(bust_marker)
	visible = true
	is_on_bust = true
	play_bust_idle()

func hide_raven() -> void:
	visible = false

func play_window_idle() -> void:
	_play_animation(window_idle_animation)

func play_fly() -> void:
	_play_animation(fly_animation)

func play_bust_idle() -> void:
	_play_animation(bust_idle_animation)

func _play_animation(animation_name: StringName) -> void:
	if animation_player == null:
		push_warning("RavenController sem AnimationPlayer.")
		return

	if not animation_player.has_animation(animation_name):
		push_warning("Animação do corvo não encontrada: %s" % animation_name)
		return

	animation_player.play(animation_name)
