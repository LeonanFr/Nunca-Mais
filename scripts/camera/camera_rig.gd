extends Node3D

const FOCUS_ROOT: StringName = &"root"

@export var turn_angle: float = 90.0
@export var turn_duration: float = 0.3
@export var focus_duration: float = 0.35
@export var start_side: int = 0

@export var camera: Camera3D

@export_group("Room View Markers")
@export var marker_0: Marker3D
@export var marker_90: Marker3D
@export var marker_180: Marker3D
@export var marker_270: Marker3D

@export_group("Focus")
@export var focus_points: Array[CameraFocusPoint] = []

var current_side: int = 0
var current_focus_id: StringName = FOCUS_ROOT
var is_moving_camera: bool = false

var focus_stack: Array[Dictionary] = []
var focus_points_by_id: Dictionary = {}

func _ready() -> void:
	current_side = wrapi(start_side, 0, 4)

	if camera == null:
		camera = $Camera3D

	_build_focus_dictionary()

	rotation_degrees.y = current_side * turn_angle
	_snap_camera_to_room_marker()

func _unhandled_input(event: InputEvent) -> void:
	
	if GameState.has_method("is_gameplay_input_locked") and GameState.is_gameplay_input_locked():
		return
	
	if _ui_blocks_world_input():
		return

	if is_moving_camera:
		return

	if event.is_action_pressed("camera_back"):
		exit_focus()
		return

	if is_in_focus():
		return

	if event.is_action_pressed("look_left"):
		turn(1)

	elif event.is_action_pressed("look_right"):
		turn(-1)

func turn(direction: int) -> void:
	is_moving_camera = true

	current_side = wrapi(current_side + direction, 0, 4)

	var target_marker := _get_room_marker_for_side(current_side)

	if target_marker == null:
		push_warning("Nenhum marker de visão configurado para o lado: %s" % current_side)
		is_moving_camera = false
		return

	var target_rotation_y := rotation_degrees.y + direction * turn_angle

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		self,
		"rotation_degrees:y",
		target_rotation_y,
		turn_duration
	)

	tween.tween_property(
		camera,
		"global_position",
		target_marker.global_position,
		turn_duration
	)

	await tween.finished

	rotation_degrees.y = current_side * turn_angle
	camera.global_position = target_marker.global_position

	is_moving_camera = false

func try_focus(target_focus_id: StringName) -> void:
	if is_moving_camera:
		return

	if not focus_points_by_id.has(target_focus_id):
		push_warning("Foco não registrado: %s" % target_focus_id)
		return

	var target_focus: CameraFocusPoint = focus_points_by_id[target_focus_id]

	if not can_focus(target_focus):
		print("Foco bloqueado: ", current_focus_id, " -> ", target_focus_id)
		return

	await focus_on(target_focus)


func can_focus(target_focus: CameraFocusPoint) -> bool:
	return target_focus.parent_focus_id == current_focus_id

func focus_on(target_focus: CameraFocusPoint) -> void:
	is_moving_camera = true

	focus_stack.append({
		"focus_id": current_focus_id,
		"position": camera.global_position,
		"rotation": camera.global_rotation
	})

	current_focus_id = target_focus.focus_id

	await _move_camera_to_transform(
		target_focus.global_position,
		target_focus.global_rotation,
		focus_duration
	)

	is_moving_camera = false

func exit_focus() -> void:
	if is_moving_camera:
		return

	if focus_stack.is_empty():
		return

	is_moving_camera = true

	var previous_view: Dictionary = focus_stack.pop_back() as Dictionary

	var previous_focus_id: StringName = previous_view["focus_id"] as StringName
	var previous_position: Vector3 = previous_view["position"] as Vector3
	var previous_rotation: Vector3 = previous_view["rotation"] as Vector3

	current_focus_id = previous_focus_id

	await _move_camera_to_transform(
		previous_position,
		previous_rotation,
		focus_duration
	)

	is_moving_camera = false

func _move_camera_to_transform(target_position: Vector3, target_rotation: Vector3, duration: float) -> void:
	var start_position: Vector3 = camera.global_position
	var start_rotation: Vector3 = camera.global_rotation

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_method(
		func(weight: float) -> void:
			camera.global_position = start_position.lerp(target_position, weight)

			var new_rotation: Vector3 = Vector3.ZERO
			new_rotation.x = lerp_angle(start_rotation.x, target_rotation.x, weight)
			new_rotation.y = lerp_angle(start_rotation.y, target_rotation.y, weight)
			new_rotation.z = lerp_angle(start_rotation.z, target_rotation.z, weight)

			camera.global_rotation = new_rotation,
		0.0,
		1.0,
		duration
	)

	await tween.finished

	camera.global_position = target_position
	camera.global_rotation = target_rotation

func can_focus_id(target_focus_id: StringName) -> bool:
	if not focus_points_by_id.has(target_focus_id):
		return false

	var target_focus: CameraFocusPoint = focus_points_by_id[target_focus_id]

	return can_focus(target_focus)

func is_in_focus() -> bool:
	return current_focus_id != FOCUS_ROOT

func get_current_focus_id() -> StringName:
	return current_focus_id

func _build_focus_dictionary() -> void:
	focus_points_by_id.clear()

	for focus_point in focus_points:
		if focus_point == null:
			continue

		if focus_point.focus_id == &"":
			push_warning("Há um CameraFocusPoint sem focus_id.")
			continue

		if focus_points_by_id.has(focus_point.focus_id):
			push_warning("Foco duplicado: %s" % focus_point.focus_id)
			continue

		focus_points_by_id[focus_point.focus_id] = focus_point

func _get_room_marker_for_side(side: int) -> Marker3D:
	match side:
		0:
			return marker_0
		1:
			return marker_90
		2:
			return marker_180
		3:
			return marker_270
		_:
			return null

func _snap_camera_to_room_marker() -> void:
	var marker := _get_room_marker_for_side(current_side)

	if marker != null:
		camera.global_position = marker.global_position

func _ui_blocks_world_input() -> bool:
	var ui := get_tree().get_first_node_in_group("ui")

	if ui == null:
		return false

	if not ui.has_method("blocks_world_input"):
		return false

	return ui.call("blocks_world_input")
