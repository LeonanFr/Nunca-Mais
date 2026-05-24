extends Node3D

@export var turn_angle: float = 90.0
@export var turn_duration: float = 0.3
@export var start_side: int = 0

var current_side: int = 0
var is_turning: bool = false

func _ready() -> void:
	current_side = wrapi(start_side, 0, 4)
	rotation_degrees.y = current_side * turn_angle

func _unhandled_input(event: InputEvent) -> void:
	if is_turning:
		return

	if event.is_action_pressed("look_left"):
		turn(1)

	elif event.is_action_pressed("look_right"):
		turn(-1)

func turn(direction: int) -> void:
	is_turning = true

	current_side = wrapi(current_side + direction, 0, 4)

	var target_y := rotation_degrees.y + direction * turn_angle

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(
		self,
		"rotation_degrees:y",
		target_y,
		turn_duration
	)

	await tween.finished

	rotation_degrees.y = current_side * turn_angle
	is_turning = false
