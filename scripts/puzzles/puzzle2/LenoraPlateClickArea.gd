extends Area3D
class_name LenoraPlateClickArea

@export var plate: LenoraPlate
@export var required_focus_id: String = "lenora"

func _ready() -> void:
	if plate == null:
		var parent := get_parent()

		if parent is LenoraPlate:
			plate = parent

func interact(camera_rig = null) -> void:
	if plate == null:
		push_warning("ClickArea sem LenoraPlate configurada.")
		return

	plate.interact(camera_rig)

func secondary_interact(camera_rig = null) -> void:
	if plate == null:
		push_warning("ClickArea sem LenoraPlate configurada.")
		return

	plate.secondary_interact(camera_rig)
