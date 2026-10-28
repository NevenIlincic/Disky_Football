extends Node2D

const BUTTON_HOVER_SOUND = preload("uid://0ot8ob1kvukc")
const GOAL_SCORED_SOUND = preload("uid://w5orqjfikx3d")
const KICK_SOUND = preload("uid://dvgr72tdkreqj")
const PLAYER_COLLIDE_SOUND = preload("uid://bxisrrdrfathw")
const PLAYER_MOVE_SOUND = preload("uid://c6ya1gpj13qcy")
const REFEREE_WHISTLE_SOUND = preload("uid://c8c7stegv8vly")

var is_audio_muted: bool = false

func _play_sound(audio_stream, volume = null, pitch = null) -> void:
	if is_audio_muted:
		return
		
	var audio: AudioStreamPlayer = AudioStreamPlayer.new()
	add_child(audio)
	audio.stream = audio_stream
	if volume:
		audio.volume_db = volume
	if pitch:
		audio.pitch_scale = pitch
	
	audio.play()
	audio.finished.connect(
		func():
			audio.queue_free()
	)

func play_hover_sound(volume = null, pitch_scale = null):
	_play_sound(BUTTON_HOVER_SOUND, volume, pitch_scale)	
func play_goal_scored_sound(volume = null, pitch_scale = null):
	_play_sound(GOAL_SCORED_SOUND, volume, pitch_scale)
func play_kick_sound(volume = null, pitch_scale = null):
	_play_sound(KICK_SOUND, volume, pitch_scale)
func play_player_collide_sound(volume = null, pitch_scale = null):
	_play_sound(PLAYER_COLLIDE_SOUND, volume, pitch_scale)
func play_player_move_sound(volume = null, pitch_scale = null):
	_play_sound(PLAYER_MOVE_SOUND, volume, pitch_scale)
func play_referee_whistle_sound(volume = null, pitch_scale = null):
	_play_sound(REFEREE_WHISTLE_SOUND, volume, pitch_scale)
