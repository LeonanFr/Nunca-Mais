extends Node3D
class_name LenoraPlate

@export var label: Label3D
@export var controller: Node
@export var start_letter: String = "A"

var current_index: int = 0
var locked: bool = false

const LETTERS := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

func _ready() -> void:
	current_index = LETTERS.find(start_letter.to_upper())

	if current_index < 0:
		current_index = 0

	_update_label()

func interact(_camera_rig = null) -> void:
	if controller != null and controller.has_method("try_advance_plate"):
		controller.try_advance_plate(self, 1)
		return

	if locked:
		return

	push_warning("LenoraPlate sem controller configurado.")

func secondary_interact(_camera_rig = null) -> void:
	if controller != null and controller.has_method("try_advance_plate"):
		controller.try_advance_plate(self, -1)
		return

	if locked:
		return

	push_warning("LenoraPlate sem controller configurado.")

func advance_letter(direction: int = 1) -> void:
	current_index += direction

	if current_index >= LETTERS.length():
		current_index = 0
	elif current_index < 0:
		current_index = LETTERS.length() - 1

	_update_label()

func get_letter() -> String:
	return LETTERS[current_index]

func set_locked(value: bool) -> void:
	locked = value

func reset_to_start() -> void:
	current_index = LETTERS.find(start_letter.to_upper())

	if current_index < 0:
		current_index = 0

	_update_label()

func _update_label() -> void:
	if label != null:
		label.text = get_letter()
