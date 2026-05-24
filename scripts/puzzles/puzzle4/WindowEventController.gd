extends Node
class_name WindowEventController

signal window_event_finished

@export var required_state: int = 4

@export var raven: RavenController
@export var window_start_marker: Node3D
@export var path_markers: Array[Node3D] = []
@export var bust_target_marker: Node3D
@export var fragment_paper: Node3D

@export var window_group: StringName = &"puzzle_window"
@export var sofa_focus_group: StringName = &"couch_focus"
@export var fly_total_duration: float = 4.0
@export var segment_durations: Array[float] = [0.45, 1.25, 1.3]

@export_group("Debug")
@export var debug_enabled: bool = false
@export var debug_force_state_on_ready: bool = false

var raven_prepared_for_window: bool = false
var event_done: bool = false
var event_running: bool = false

func _ready() -> void:
	add_to_group("window_event_controller")
	if debug_enabled and debug_force_state_on_ready:
		GameState.puzzle_state = required_state
	_setup_fragment()
	_setup_initial_state()

func _unhandled_input(event: InputEvent) -> void:
	if not debug_enabled:
		return
	var key_event := event as InputEventKey
	if key_event == null:
		return
	if not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_F5:
			_debug_prepare_window_state()
		KEY_F6:
			_debug_trigger_window_event()
		KEY_F7:
			_debug_reset_window_event()

func _process(_delta: float) -> void:
	if event_done:
		return
	if raven_prepared_for_window:
		return
	if GameState.puzzle_state == required_state:
		_prepare_raven_at_window()

func trigger_window_event() -> void:
	if event_running:
		return
	if event_done:
		_show_feedback("Era um Corvo hierático e soberbo, egresso de eras ancestrais.")
		return
	if GameState.puzzle_state < required_state:
		_show_feedback("É o vento só, e nada mais.")
		return
	if GameState.puzzle_state > required_state:
		_show_feedback("Como um fidalgo passou, augusto e, sem notar sequer meu susto, adejou e pousou sobre o busto, uma escultura de Minerva.")
		return
	event_running = true
	event_done = true
	if not raven_prepared_for_window:
		_prepare_raven_at_window()
	_show_feedback("Em tumulto, a esvoaçar, penetra um vulto.")
	_open_window()
	if raven != null:
		await _move_raven_to_bust()
	_close_window()
	_unlock_sofa_focus()
	_release_fragment()
	event_running = false
	window_event_finished.emit()

func _setup_initial_state() -> void:
	if GameState.puzzle_state < required_state:
		if raven != null:
			raven.hide_raven()
		return
	if GameState.puzzle_state == required_state:
		_prepare_raven_at_window()
		return
	if GameState.puzzle_state > required_state:
		event_done = true
		if raven != null:
			raven.setup_at_bust(bust_target_marker)
		_close_window()
		_unlock_sofa_focus()
		return

func _prepare_raven_at_window() -> void:
	if raven == null:
		return
	raven_prepared_for_window = true
	raven.setup_at_window(window_start_marker)

func _setup_fragment() -> void:
	if fragment_paper == null:
		return
	if fragment_paper.has_method("set_available"):
		fragment_paper.set_available(false)

func _open_window() -> void:
	get_tree().call_group(window_group, "open_window")

func _close_window() -> void:
	get_tree().call_group(window_group, "close_window")

func _move_raven_to_bust() -> void:
	if raven == null:
		return
	raven.visible = true
	raven.play_fly()
	var points: Array[Node3D] = []
	for marker in path_markers:
		if marker != null:
			points.append(marker)
	if bust_target_marker != null:
		points.append(bust_target_marker)
	if points.is_empty():
		if bust_target_marker != null:
			raven.setup_at_bust(bust_target_marker)
		return
	var default_segment_duration: float = fly_total_duration / float(points.size())
	for index in range(points.size()):
		var point: Node3D = points[index]
		var segment_duration: float = _get_segment_duration(index, default_segment_duration)
		await _move_raven_to_marker(point, segment_duration)
		raven.apply_marker_transform(point)
	if bust_target_marker != null:
		raven.setup_at_bust(bust_target_marker)
	else:
		raven.play_bust_idle()

func _get_segment_duration(index: int, fallback_duration: float) -> float:
	if index < 0:
		return fallback_duration
	if index >= segment_durations.size():
		return fallback_duration
	if segment_durations[index] <= 0.0:
		return fallback_duration
	return segment_durations[index]

func _move_raven_to_marker(marker: Node3D, duration: float) -> void:
	if raven == null or marker == null:
		return
	var start_position: Vector3 = raven.global_position
	var target_position: Vector3 = marker.global_position
	var start_rotation: Vector3 = raven.global_rotation
	var target_rotation: Vector3 = marker.global_rotation
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(
		func(weight: float) -> void:
			raven.global_position = start_position.lerp(target_position, weight)
			var new_rotation: Vector3 = Vector3.ZERO
			new_rotation.x = lerp_angle(start_rotation.x, target_rotation.x, weight)
			new_rotation.y = lerp_angle(start_rotation.y, target_rotation.y, weight)
			new_rotation.z = lerp_angle(start_rotation.z, target_rotation.z, weight)
			raven.global_rotation = new_rotation,
		0.0,
		1.0,
		duration
	)
	await tween.finished

func _release_fragment() -> void:
	if fragment_paper == null:
		push_warning("WindowEventController sem fragment_paper.")
		return
	if fragment_paper.has_method("set_available"):
		fragment_paper.set_available(true)

func _unlock_sofa_focus() -> void:
	get_tree().call_group(sofa_focus_group, "unlock_focus")

func _show_feedback(text: String) -> void:
	get_tree().call_group("ui", "show_feedback", text)

func _debug_prepare_window_state() -> void:
	GameState.puzzle_state = required_state
	event_done = false
	event_running = false
	raven_prepared_for_window = false
	_setup_fragment()
	_prepare_raven_at_window()
	_close_window()
	_show_feedback("DEBUG: corvo preparado na janela.")

func _debug_trigger_window_event() -> void:
	GameState.puzzle_state = required_state
	if not raven_prepared_for_window:
		_prepare_raven_at_window()
	trigger_window_event()

func _debug_reset_window_event() -> void:
	event_done = false
	event_running = false
	raven_prepared_for_window = false
	if fragment_paper != null and fragment_paper.has_method("set_available"):
		fragment_paper.set_available(false)
	_close_window()
	_lock_sofa_focus()
	if raven != null:
		raven.setup_at_window(window_start_marker)
	raven_prepared_for_window = true
	_show_feedback("DEBUG: evento da janela resetado.")

func _lock_sofa_focus() -> void:
	get_tree().call_group(sofa_focus_group, "lock_focus")
