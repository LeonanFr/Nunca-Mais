@tool
extends EditorScript

const ANIMATION_PLAYER_PATH := "AnimationPlayer"

const OLD_PREFIX := "Sketchfab_model/f49d25f511314a49b13a692940e42945_fbx/Object_2/RootNode/SK_Crow/root/Object_6/Skeleton3D"
const NEW_PREFIX := "CrowModel/Skeleton3D"


func _run() -> void:
	var scene_root: Node = get_editor_interface().get_edited_scene_root()

	if scene_root == null:
		push_error("Nenhuma cena aberta.")
		return

	var animation_player: AnimationPlayer = scene_root.get_node_or_null(ANIMATION_PLAYER_PATH) as AnimationPlayer

	if animation_player == null:
		push_error("AnimationPlayer não encontrado em: " + ANIMATION_PLAYER_PATH)
		return

	var changed_tracks := 0

	for library_name in animation_player.get_animation_library_list():
		var library: AnimationLibrary = animation_player.get_animation_library(library_name)

		if library == null:
			continue

		for animation_name in library.get_animation_list():
			var animation: Animation = library.get_animation(animation_name)

			if animation == null:
				continue

			for track_index in range(animation.get_track_count()):
				var old_track_path: String = str(animation.track_get_path(track_index))

				if old_track_path.begins_with(OLD_PREFIX):
					var suffix: String = old_track_path.substr(OLD_PREFIX.length())
					var new_track_path: String = NEW_PREFIX + suffix

					animation.track_set_path(track_index, NodePath(new_track_path))

					print("Atualizado em animação '", animation_name, "':")
					print("  antigo: ", old_track_path)
					print("  novo:   ", new_track_path)

					changed_tracks += 1

	print("--------------------------------")
	print("Tracks atualizadas: ", changed_tracks)
	print("Teste a animação e salve a cena manualmente.")
