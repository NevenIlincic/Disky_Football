class_name MultiplayerPauseMenu extends Control

var scene: MultiplayerScene

#func _exit_tree() -> void:
	#if Fusion.room_left.is_connected(_on_room_left):
		#Fusion.room_left.disconnect(_on_room_left)

func _ready() -> void:
	scene = get_tree().get_first_node_in_group("multiplayer_scene")
	#Fusion.room_left.connect(_on_room_left)

func _on_leave_button_pressed() -> void:
	FusionSdk.leave_room()
	get_tree().change_scene_to_file("res://Scenes/Menus/Multiplayer_Menu_Scene.tscn")
