class_name MultiplayerMenu extends Control

signal disconnected_from_multiplayer()

var logged_in_player_stats: LoggedPlayerStats

@onready var not_searching_node: Control = $Not_Searching_Node
@onready var while_searching_node: Control = $While_Searching_Node
@onready var match_found_node: Control = $Match_Found_Node

@onready var searching_animation_player: AnimationPlayer = $Searching_Animation_Player
#LABELS
@onready var searching_label: Label = $While_Searching_Node/Searching_Label
@onready var host_name_label: Label = $Match_Found_Node/Host_Name_Label
@onready var guest_name_label: Label = $Match_Found_Node/Guest_Name_Label
@onready var host_team_name_label: Label = $Match_Found_Node/Host_Team_Name_Label
@onready var guest_team_name_label: Label = $Match_Found_Node/Guest_Team_Name_Label


func _ready() -> void:
	Fusion.register_broadcast_receiver(self)
	Fusion.room_left.connect(_on_search_canceled)
	FusionSdk.match_found.connect(prepare_match_info)
	logged_in_player_stats = get_tree().get_first_node_in_group("logged_player_stats")

func _exit_tree() -> void:
	Fusion.unregister_broadcast_receiver(self)
	if Fusion.room_left.is_connected(_on_search_canceled):
		Fusion.room_left.disconnect(_on_search_canceled)
	if FusionSdk.match_found.is_connected(prepare_match_info):
		FusionSdk.match_found.disconnect(prepare_match_info)
@rpc("any_peer","call_local")
func _on_match_found():
	logged_in_player_stats.hide_stats()
	not_searching_node.visible = false
	while_searching_node.visible = false
	match_found_node.visible = true
	var opponents_name: String = FusionSdk.get_opponents_name()
	var opponents_team_name: String = FusionSdk.get_opponents_team_name()
	if Fusion.is_master_client():
		host_name_label.text = get_my_name()
		guest_name_label.text = str("COACH: ", opponents_name)
		host_team_name_label.text = get_my_team_name()
		guest_team_name_label.text = str("TEAM: ", opponents_team_name)
	else:
		host_name_label.text = str("COACH: ", opponents_name)
		guest_name_label.text = get_my_name()
		host_team_name_label.text = str("TEAM: ", opponents_team_name)
		guest_team_name_label.text = get_my_team_name()
		
	await get_tree().create_timer(3.0).timeout
	if Fusion.is_master_client():
		Fusion.rpc(FusionSdk.start_match)
		Fusion.unregister_broadcast_receiver(self)


func prepare_match_info():
	Fusion.rpc(_on_match_found)

func _on_join_button_pressed() -> void:
	show_while_searching_node()
	FusionSdk.create_room()


func _on_back_button_pressed() -> void:
	Fusion.disconnect_from_photon()
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu_Scene.tscn")
	

func _on_cancel_searching_button_pressed() -> void:
	if Fusion.is_in_room():
		FusionSdk.leave_room()
	
func _on_search_canceled():
	show_not_searching_node()
	
func show_not_searching_node():
	searching_label.visible = false
	searching_animation_player.stop()
	not_searching_node.visible = true
	while_searching_node.visible = false

func show_while_searching_node():
	searching_label.visible = true
	searching_animation_player.play("Searching_Animation")
	not_searching_node.visible = false
	while_searching_node.visible = true

func get_my_name() -> String:
	#ZAMENI SA PLAYGAMA SDK
	return str("COACH: ", FusionSdk.my_name) 

func get_my_team_name() -> String:
	return str("TEAM: ", FusionSdk.my_team_name)
