extends Node

@export_group("Ambiente")
@export var ambient_music: AudioStream
@export var rain_loop: AudioStream
@export_range(-40.0, 6.0, 0.5) var ambient_music_volume_db := -12.0
@export_range(-40.0, 6.0, 0.5) var rain_volume_db := -10.0

@export_group("Poemas")
@export var fragment_narrations: Array[AudioStream] = []
@export_range(-40.0, 10.0, 0.5) var poem_volume_db := 0.0

@export_group("Corvo")
@export var raven_sound: AudioStream
@export_range(-40.0, 8.0, 0.5) var raven_volume_db := -2.0

@export_group("Porta / Sinos")
@export var door_knock_sound: AudioStream
@export var bell_sound: AudioStream
@export var bell_hit_gap := 0.5
@export var door_hit_gap := 0.18
@export var door_group_gap := 0.7
@export_range(-40.0, 6.0, 0.5) var door_knock_volume_db := 0.0
@export_range(-40.0, 6.0, 0.5) var bell_volume_db := 0.0

@export_group("Final")
@export var final_narration: AudioStream
@export var final_nevermore: AudioStream
@export_range(-40.0, 10.0, 0.5) var final_narration_volume_db := 0.0
@export_range(-40.0, 10.0, 0.5) var final_nevermore_volume_db := 0.0

@onready var ambient_music_player: AudioStreamPlayer = $AmbientMusicPlayer
@onready var rain_player: AudioStreamPlayer = $RainPlayer
@onready var poem_narration_player: AudioStreamPlayer = $PoemNarrationPlayer
@onready var raven_player: AudioStreamPlayer = $RavenPlayer
@onready var door_knock_player: AudioStreamPlayer = $DoorKnockPlayer
@onready var final_narration_player: AudioStreamPlayer = $FinalNarrationPlayer
@onready var final_nevermore_player: AudioStreamPlayer = $FinalNevermorePlayer

var door_knock_sequence_id := 0
var bell_sequence_id := 0

func start_ambient() -> void:
	if ambient_music != null:
		ambient_music_player.stream = ambient_music
		ambient_music_player.volume_db = ambient_music_volume_db
		
		if not ambient_music_player.playing:
			ambient_music_player.play()
	
	if rain_loop != null:
		rain_player.stream = rain_loop
		rain_player.volume_db = rain_volume_db
		
		if not rain_player.playing:
			rain_player.play()

func stop_ambient() -> void:
	ambient_music_player.stop()
	rain_player.stop()

func play_fragment_narration(fragment_id: int) -> void:
	var index := fragment_id - 1
	
	if index < 0 or index >= fragment_narrations.size():
		return
	
	var stream := fragment_narrations[index]
	
	if stream == null:
		return
	
	poem_narration_player.stop()
	poem_narration_player.stream = stream
	poem_narration_player.volume_db = poem_volume_db
	poem_narration_player.play()

func stop_fragment_narration() -> void:
	poem_narration_player.stop()

func play_raven() -> void:
	if raven_sound == null:
		return
	
	raven_player.stop()
	raven_player.stream = raven_sound
	raven_player.volume_db = raven_volume_db
	raven_player.play()

func play_door_knock_sequence(sequence: Array[int]) -> void:
	if door_knock_sound == null:
		return
	
	door_knock_sequence_id += 1
	var current_sequence_id := door_knock_sequence_id
	
	_play_door_knock_sequence_async(sequence, current_sequence_id)

func _play_door_knock_sequence_async(sequence: Array[int], sequence_id: int) -> void:
	for group_index in range(sequence.size()):
		if sequence_id != door_knock_sequence_id:
			return
		
		var count: int = clampi(sequence[group_index], 1, 10)
		
		for hit_index in range(count):
			if sequence_id != door_knock_sequence_id:
				return
			
			_play_one_shot(door_knock_sound, door_knock_volume_db)
			
			if hit_index < count - 1:
				await get_tree().create_timer(door_hit_gap).timeout
		
		if group_index < sequence.size() - 1:
			await get_tree().create_timer(door_group_gap).timeout

func play_bell_count(count: int) -> void:
	if bell_sound == null:
		return
	
	bell_sequence_id += 1
	var current_sequence_id := bell_sequence_id
	
	_play_repeated_sound(
		bell_sound,
		count,
		bell_hit_gap,
		bell_volume_db,
		current_sequence_id,
		"bell"
	)

func _play_repeated_sound(
	stream: AudioStream,
	count: int,
	gap: float,
	volume_db: float,
	sequence_id: int,
	sequence_type: String
) -> void:
	count = clampi(count, 1, 10)
	
	for i in range(count):
		if sequence_type == "door" and sequence_id != door_knock_sequence_id:
			return
		
		if sequence_type == "bell" and sequence_id != bell_sequence_id:
			return
		
		_play_one_shot(stream, volume_db)
		
		if i < count - 1:
			await get_tree().create_timer(gap).timeout

func _play_one_shot(stream: AudioStream, volume_db: float) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	
	player.stream = stream
	player.volume_db = volume_db
	player.play()
	
	player.finished.connect(player.queue_free)

func play_final_narration() -> float:
	if final_narration == null:
		return 0.0
	
	final_narration_player.stop()
	final_narration_player.stream = final_narration
	final_narration_player.volume_db = final_narration_volume_db
	final_narration_player.play()
	
	return final_narration.get_length()

func play_final_nevermore() -> void:
	if final_nevermore == null:
		return
	
	final_nevermore_player.stop()
	final_nevermore_player.stream = final_nevermore
	final_nevermore_player.volume_db = final_nevermore_volume_db
	final_nevermore_player.play()

func stop_final_narration() -> void:
	final_narration_player.stop()

func stop_all() -> void:
	door_knock_sequence_id += 1
	bell_sequence_id += 1
	
	ambient_music_player.stop()
	rain_player.stop()
	poem_narration_player.stop()
	raven_player.stop()
	door_knock_player.stop()
	final_narration_player.stop()
	final_nevermore_player.stop()
	
	for child in get_children():
		if child is AudioStreamPlayer:
			if child not in [
				ambient_music_player,
				rain_player,
				poem_narration_player,
				raven_player,
				door_knock_player,
				final_narration_player,
				final_nevermore_player
			]:
				child.queue_free()
