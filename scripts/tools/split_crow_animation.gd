@tool
extends EditorScript

const ANIMATION_PLAYER_PATH := "AnimationPlayer"
const SOURCE_ANIMATION_NAME := "root|TakeOff"

const SPLITS := [
	{
		"name": "window_look",
		"start": 0.0,
		"end": 1.0,
		"loop": true,
		"pingpong": true
	},
	{
		"name": "bust_look",
		"start": 2.5,
		"end": 6.4,
		"loop": true,
		"pingpong": true
	},
	{
		"name": "fly_to_bust",
		"start": 6.7,
		"end": 10.52,
		"loop": false,
		"pingpong": false
	}
]


func _run() -> void:
	var scene_root: Node = get_editor_interface().get_edited_scene_root()

	if scene_root == null:
		push_error("Nenhuma cena aberta.")
		return

	var animation_player: AnimationPlayer = scene_root.get_node_or_null(ANIMATION_PLAYER_PATH) as AnimationPlayer

	if animation_player == null:
		push_error("AnimationPlayer não encontrado em: " + ANIMATION_PLAYER_PATH)
		return

	var source_animation: Animation = null
	var target_library: AnimationLibrary = null

	for library_name: StringName in animation_player.get_animation_library_list():
		var library: AnimationLibrary = animation_player.get_animation_library(library_name)

		if library == null:
			continue

		if library.has_animation(SOURCE_ANIMATION_NAME):
			source_animation = library.get_animation(SOURCE_ANIMATION_NAME)
			target_library = library
			break

	if source_animation == null or target_library == null:
		push_error("Animação fonte não encontrada: " + SOURCE_ANIMATION_NAME)
		return

	for split_data: Dictionary in SPLITS:
		var animation_name: StringName = StringName(str(split_data["name"]))
		var start_time: float = float(split_data["start"])
		var end_time: float = float(split_data["end"])
		var should_loop: bool = bool(split_data["loop"])
		var should_pingpong: bool = bool(split_data["pingpong"])

		var new_animation: Animation = _make_animation_slice(
			source_animation,
			start_time,
			end_time,
			should_loop,
			should_pingpong
		)

		if target_library.has_animation(animation_name):
			target_library.remove_animation(animation_name)

		target_library.add_animation(animation_name, new_animation)

		print("Criada animação: ", animation_name)
		print("  trecho: ", start_time, " -> ", end_time)
		print("  loop: ", should_loop)
		print("  pingpong: ", should_pingpong)

	print("--------------------------------")
	print("Split concluído.")
	print("Teste window_look, bust_look e fly_to_bust no AnimationPlayer.")
	print("Depois salve a cena manualmente.")


func _make_animation_slice(
	source: Animation,
	start_time: float,
	end_time: float,
	should_loop: bool,
	should_pingpong: bool
) -> Animation:
	var new_animation: Animation = Animation.new()
	var new_length: float = maxf(0.01, end_time - start_time)

	new_animation.length = new_length

	if should_pingpong:
		new_animation.loop_mode = Animation.LOOP_PINGPONG
	elif should_loop:
		new_animation.loop_mode = Animation.LOOP_LINEAR
	else:
		new_animation.loop_mode = Animation.LOOP_NONE

	for source_track_index: int in range(source.get_track_count()):
		var track_type: int = int(source.track_get_type(source_track_index))
		var new_track_index: int = new_animation.add_track(track_type)

		new_animation.track_set_path(
			new_track_index,
			source.track_get_path(source_track_index)
		)

		new_animation.track_set_enabled(
			new_track_index,
			source.track_is_enabled(source_track_index)
		)

		new_animation.track_set_interpolation_type(
			new_track_index,
			source.track_get_interpolation_type(source_track_index)
		)

		new_animation.track_set_interpolation_loop_wrap(
			new_track_index,
			source.track_get_interpolation_loop_wrap(source_track_index)
		)

		_copy_track_keys_in_range(
			source,
			source_track_index,
			new_animation,
			new_track_index,
			start_time,
			end_time
		)

	return new_animation


func _copy_track_keys_in_range(
	source: Animation,
	source_track_index: int,
	new_animation: Animation,
	new_track_index: int,
	start_time: float,
	end_time: float
) -> void:
	var inserted_start_key: bool = false
	var has_exact_end_key: bool = false

	var start_key_index: int = _find_last_key_at_or_before(source, source_track_index, start_time)

	if start_key_index >= 0:
		var start_key_value: Variant = source.track_get_key_value(source_track_index, start_key_index)
		var start_key_transition: float = source.track_get_key_transition(source_track_index, start_key_index)

		new_animation.track_insert_key(
			new_track_index,
			0.0,
			start_key_value,
			start_key_transition
		)

		inserted_start_key = true

	for key_index: int in range(source.track_get_key_count(source_track_index)):
		var key_time: float = source.track_get_key_time(source_track_index, key_index)

		if key_time < start_time:
			continue

		if key_time > end_time:
			continue

		var new_key_time: float = key_time - start_time

		if inserted_start_key and is_zero_approx(new_key_time):
			continue

		if is_equal_approx(key_time, end_time):
			has_exact_end_key = true

		var key_value: Variant = source.track_get_key_value(source_track_index, key_index)
		var key_transition: float = source.track_get_key_transition(source_track_index, key_index)

		new_animation.track_insert_key(
			new_track_index,
			new_key_time,
			key_value,
			key_transition
		)

	if not has_exact_end_key:
		var end_key_index: int = _find_first_key_at_or_after(source, source_track_index, end_time)

		if end_key_index < 0:
			end_key_index = _find_last_key_at_or_before(source, source_track_index, end_time)

		if end_key_index >= 0:
			var end_key_value: Variant = source.track_get_key_value(source_track_index, end_key_index)
			var end_key_transition: float = source.track_get_key_transition(source_track_index, end_key_index)
			var end_new_time: float = maxf(0.0, end_time - start_time)

			new_animation.track_insert_key(
				new_track_index,
				end_new_time,
				end_key_value,
				end_key_transition
			)


func _find_last_key_at_or_before(source: Animation, track_index: int, time: float) -> int:
	var result: int = -1

	for key_index: int in range(source.track_get_key_count(track_index)):
		var key_time: float = source.track_get_key_time(track_index, key_index)

		if key_time <= time:
			result = key_index
		else:
			break

	return result


func _find_first_key_at_or_after(source: Animation, track_index: int, time: float) -> int:
	for key_index: int in range(source.track_get_key_count(track_index)):
		var key_time: float = source.track_get_key_time(track_index, key_index)

		if key_time >= time:
			return key_index

	return -1
