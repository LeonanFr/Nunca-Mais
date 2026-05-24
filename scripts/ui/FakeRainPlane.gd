extends MeshInstance3D
class_name FakeRainPlane

@export var scroll_speed: Vector2 = Vector2(2.0, -0.35)
@export var uv_scale: Vector2 = Vector2(2.0, 2.0)

var material_instance: StandardMaterial3D


func _ready() -> void:
	var source_material: Material = material_override

	if source_material == null:
		source_material = get_active_material(0)

	if source_material == null:
		push_warning("FakeRainPlane: nenhum material encontrado no RainPlane.")
		return

	var standard_material := source_material as StandardMaterial3D

	if standard_material == null:
		push_warning("FakeRainPlane: o material precisa ser StandardMaterial3D.")
		return

	material_instance = standard_material.duplicate(true) as StandardMaterial3D
	material_override = material_instance

	material_instance.uv1_scale = Vector3(uv_scale.x, uv_scale.y, 1.0)

	print("FakeRainPlane funcionando com material: ", material_instance)


func _process(delta: float) -> void:
	if material_instance == null:
		return

	var offset: Vector3 = material_instance.uv1_offset
	offset.x += scroll_speed.x * delta
	offset.y += scroll_speed.y * delta
	material_instance.uv1_offset = offset
