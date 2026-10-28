class_name MultiplayerPauseMenu extends Control

var scene: Object

var is_singleplayer: bool = false
#func _exit_tree() -> void:
	#if Fusion.room_left.is_connected(_on_room_left):
		#Fusion.room_left.disconnect(_on_room_left)

func set_is_singleplayer():
	is_singleplayer = true



func _on_leave_button_pressed() -> void:
	if not is_singleplayer:
		FusionSdk.leave_room()
		get_tree().change_scene_to_file("res://Scenes/Menus/Multiplayer_Menu_Scene.tscn")
	else:
		FusionSdk.has_disconnected_intentionally = true
		get_tree().change_scene_to_file("res://Scenes/Menus/Menu_Scene.tscn")


func _on_leave_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()
