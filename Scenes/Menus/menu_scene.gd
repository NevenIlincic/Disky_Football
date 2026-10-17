extends Node3D


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Test_Scene.tscn")


func _on_create_button_pressed() -> void:
	FusionSdk.create_room()

func _on_connect_button_pressed() -> void:
	FusionSdk.connect_to_server()

func _on_join_button_pressed() -> void:
	FusionSdk.join_room()
