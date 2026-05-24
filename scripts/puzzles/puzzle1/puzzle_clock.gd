extends Node3D
class_name PuzzleClock

signal time_changed

enum RotationAxis {
	X,
	Y,
	Z
}

const MINUTES_PER_HOUR: int = 60
const MINUTES_IN_CLOCK: int = 720
const DEGREES_PER_MINUTE: float = 6.0
const DEGREES_PER_HOUR: float = 30.0

@export var focus_id: StringName = &"clock"
@export var focus_parent_id: StringName = &"root"

@export_group("Clock Parts")
@export var clock_face_center: Node3D
@export var hour_hand: Node3D
@export var minute_hand: Node3D
@export var glass: Node3D
@export var animation_player: AnimationPlayer
@export var pendulum: Node3D
@export var pendulum_rest_rotation_degrees: Vector3 = Vector3.ZERO
@export var fragment_paper_inside: Node

@export_group("Hand Rotation")
@export var hand_rotation_axis: RotationAxis = RotationAxis.Z
@export var clockwise_multiplier: float = -1.0

@export_group("Mouse Drag")
@export var minute_step: int = 5
@export var drag_direction: int = 1

@export_group("Time")
@export var start_total_minutes: int = 195 # 03:15
@export var target_total_minutes: int = 0 # 00:00

var current_total_minutes: int = 0
var is_locked: bool = false

var is_dragging: bool = false
var last_drag_angle_degrees: float = 0.0
var drag_angle_accumulator: float = 0.0

var hour_base_rotation: Vector3 = Vector3.ZERO
var minute_base_rotation: Vector3 = Vector3.ZERO


func _ready() -> void:
	if hour_hand != null:
		hour_base_rotation = hour_hand.rotation_degrees

	if minute_hand != null:
		minute_base_rotation = minute_hand.rotation_degrees

	current_total_minutes = _normalize_minutes(start_total_minutes)
	_apply_current_time_visual()


func _unhandled_input(event: InputEvent) -> void:

	if not GameState.can_use_puzzle_1():
		stop_drag()
		return
	
	if not is_dragging:
		return

	var mouse_button_event: InputEventMouseButton = event as InputEventMouseButton
	if mouse_button_event != null:
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and not mouse_button_event.pressed:
			stop_drag()
			return

	var mouse_motion_event: InputEventMouseMotion = event as InputEventMouseMotion
	if mouse_motion_event != null:
		_update_drag_from_mouse()

func has_available_fragment_paper() -> bool:
	if fragment_paper_inside == null:
		return false

	if not is_instance_valid(fragment_paper_inside):
		return false

	if not fragment_paper_inside.has_method("is_available"):
		return false

	return fragment_paper_inside.call("is_available")

func start_drag() -> void:
	if is_locked:
		_show_feedback("É hora morta. Meia-noite erma e sombria.")
		return

	if not GameState.can_use_puzzle_1():
		_show_feedback("Anseio ver a noite finda.")
		return

	var angle: float = _get_mouse_angle_degrees()

	if is_nan(angle):
		return

	is_dragging = true
	last_drag_angle_degrees = angle
	drag_angle_accumulator = 0.0

func stop_drag() -> void:
	is_dragging = false
	drag_angle_accumulator = 0.0

func is_at_target_time() -> bool:
	return current_total_minutes == _normalize_minutes(target_total_minutes)

func lock_clock() -> void:
	is_locked = true
	stop_drag()

func stop_pendulum_animation() -> void:
	if animation_player != null:
		animation_player.pause()

	if pendulum != null:
		pendulum.rotation_degrees = pendulum_rest_rotation_degrees

func hide_glass() -> void:
	if glass == null:
		return

	glass.visible = false

func release_fragment_paper() -> void:
	if fragment_paper_inside == null:
		push_warning("PuzzleClock sem fragment_paper_inside configurado.")
		return

	if not fragment_paper_inside.has_method("set_available"):
		push_warning("fragment_paper_inside não tem método set_available().")
		return

	fragment_paper_inside.call("set_available", true)

func _update_drag_from_mouse() -> void:
	var current_angle: float = _get_mouse_angle_degrees()

	if is_nan(current_angle):
		return

	var delta_angle: float = _shortest_angle_delta(last_drag_angle_degrees, current_angle)
	last_drag_angle_degrees = current_angle

	drag_angle_accumulator += delta_angle

	var degrees_per_step: float = DEGREES_PER_MINUTE * float(minute_step)

	if absf(drag_angle_accumulator) < degrees_per_step:
		return

	var steps: int = int(drag_angle_accumulator / degrees_per_step)

	if steps == 0:
		return

	drag_angle_accumulator -= float(steps) * degrees_per_step

	_add_minutes(steps * minute_step * drag_direction)

func _add_minutes(amount: int) -> void:
	current_total_minutes = _normalize_minutes(current_total_minutes + amount)
	_apply_current_time_visual()
	time_changed.emit()

func _apply_current_time_visual() -> void:
	var hour: int = floori(float(current_total_minutes) / float(MINUTES_PER_HOUR))
	var minute: int = current_total_minutes % MINUTES_PER_HOUR

	var minute_angle: float = float(minute) * DEGREES_PER_MINUTE
	var hour_angle: float = (float(hour % 12) + float(minute) / float(MINUTES_PER_HOUR)) * DEGREES_PER_HOUR

	_set_hand_angle(minute_hand, minute_base_rotation, minute_angle)
	_set_hand_angle(hour_hand, hour_base_rotation, hour_angle)

func _set_hand_angle(hand: Node3D, base_rotation: Vector3, angle_degrees: float) -> void:
	if hand == null:
		return

	var final_angle: float = angle_degrees * clockwise_multiplier
	var new_rotation: Vector3 = base_rotation

	match hand_rotation_axis:
		RotationAxis.X:
			new_rotation.x = base_rotation.x + final_angle
		RotationAxis.Y:
			new_rotation.y = base_rotation.y + final_angle
		RotationAxis.Z:
			new_rotation.z = base_rotation.z + final_angle

	hand.rotation_degrees = new_rotation

func _get_mouse_angle_degrees() -> float:
	if clock_face_center == null:
		return NAN

	var camera: Camera3D = get_viewport().get_camera_3d()

	if camera == null:
		return NAN

	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_direction: Vector3 = camera.project_ray_normal(mouse_position)

	var face_normal: Vector3 = _get_clock_face_normal()
	var face_plane: Plane = Plane(face_normal, clock_face_center.global_position)

	var hit_variant: Variant = face_plane.intersects_ray(ray_origin, ray_direction)

	if hit_variant == null:
		return NAN

	var hit_position: Vector3 = hit_variant as Vector3
	var local_hit: Vector3 = clock_face_center.to_local(hit_position)

	return _get_clock_angle_from_local_point(local_hit)

func _get_clock_face_normal() -> Vector3:
	var face_basis: Basis = clock_face_center.global_transform.basis

	match hand_rotation_axis:
		RotationAxis.X:
			return face_basis.x.normalized()
		RotationAxis.Y:
			return face_basis.y.normalized()
		RotationAxis.Z:
			return face_basis.z.normalized()

	return face_basis.z.normalized()

func _get_clock_angle_from_local_point(local_point: Vector3) -> float:
	match hand_rotation_axis:
		RotationAxis.X:
			return fposmod(rad_to_deg(atan2(local_point.z, local_point.y)), 360.0)

		RotationAxis.Y:
			return fposmod(rad_to_deg(atan2(local_point.x, local_point.z)), 360.0)

		RotationAxis.Z:
			return fposmod(rad_to_deg(atan2(local_point.x, local_point.y)), 360.0)

	return 0.0

func _shortest_angle_delta(from_degrees: float, to_degrees: float) -> float:
	return fposmod(to_degrees - from_degrees + 180.0, 360.0) - 180.0

func _normalize_minutes(value: int) -> int:
	return posmod(value, MINUTES_IN_CLOCK)

func _show_feedback(text: String) -> void:
	get_tree().call_group("ui", "show_feedback", text)
