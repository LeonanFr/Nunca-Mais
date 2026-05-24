extends Node
class_name MouseInteractor

@export var camera: Camera3D
@export var camera_rig: Node
@export var max_distance: float = 50.0

@export_flags_3d_physics var collision_mask: int = 2

func _unhandled_input(event: InputEvent) -> void:
	if GameState.has_method("is_gameplay_input_locked") and GameState.is_gameplay_input_locked():
		return
	
	if _ui_blocks_world_input():
		return

	if event.is_action_pressed("interact_click"):
		_try_interact_at_mouse(false)
		return

	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			_try_interact_at_mouse(true)
			return

func _try_interact_at_mouse(use_secondary: bool = false) -> void:
	if camera == null:
		push_warning("MouseInteractor sem Camera3D configurada.")
		return

	var viewport: Viewport = get_viewport()
	var mouse_position: Vector2 = viewport.get_mouse_position()

	var ray_origin: Vector3 = camera.project_ray_origin(mouse_position)
	var ray_direction: Vector3 = camera.project_ray_normal(mouse_position)
	var ray_end: Vector3 = ray_origin + ray_direction * max_distance

	var excluded_rids: Array[RID] = []
	var max_attempts: int = 12

	for attempt in range(max_attempts):
		var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.collision_mask = collision_mask
		query.collide_with_areas = true
		query.collide_with_bodies = false
		query.exclude = excluded_rids

		var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state
		var result: Dictionary = space_state.intersect_ray(query)

		if result.is_empty():
			return

		var collider: Object = result["collider"] as Object
		var interactable: Node = _find_interactable(collider)

		if interactable == null:
			if result.has("rid"):
				excluded_rids.append(result["rid"] as RID)
				continue

			return

		if _can_interact_with(interactable):
			_call_interaction(interactable, use_secondary)
			return

		if result.has("rid"):
			excluded_rids.append(result["rid"] as RID)
		else:
			return

func _call_interaction(interactable: Node, use_secondary: bool) -> void:
	if use_secondary:
		if interactable.has_method("secondary_interact"):
			interactable.call("secondary_interact", camera_rig)
		return

	if interactable.has_method("interact"):
		interactable.call("interact", camera_rig)

func _can_interact_with(interactable: Node) -> bool:
	if interactable.has_method("can_interact"):
		return interactable.call("can_interact", camera_rig)

	return true

func _find_interactable(collider: Object) -> Node:
	var current_node: Node = collider as Node

	while current_node != null:
		if current_node.has_method("interact") or current_node.has_method("secondary_interact"):
			return current_node

		current_node = current_node.get_parent()

	return null

func _ui_blocks_world_input() -> bool:
	var ui := get_tree().get_first_node_in_group("ui")

	if ui == null:
		return false

	if not ui.has_method("blocks_world_input"):
		return false

	return ui.call("blocks_world_input")
