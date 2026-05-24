extends Area3D

func interact(camera_rig = null) -> void:
	var paper := get_parent()

	if paper and paper.has_method("interact"):
		paper.interact(camera_rig)
