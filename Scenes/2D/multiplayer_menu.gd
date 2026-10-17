class_name MultiplayerMenu extends Control

signal disconnected_from_multiplayer()

@onready var not_searching_node: Control = $Not_Searching_Node
@onready var while_searching_node: Control = $While_Searching_Node
@onready var match_found_node: Control = $Match_Found_Node

@onready var searching_animation_player: AnimationPlayer = $Searching_Animation_Player
#LABELS
@onready var searching_label: Label = $While_Searching_Node/Searching_Label
@onready var host_name_label: Label = $Match_Found_Node/Host_Name_Label
@onready var guest_name_label: Label = $Match_Found_Node/Guest_Name_Label


func _ready() -> void:
	Fusion.register_broadcast_receiver(self)
	Fusion.room_left.connect(_on_search_canceled)
	FusionSdk.match_found.connect(prepare_match_info)

@rpc("any_peer","call_local")
func _on_match_found():
	not_searching_node.visible = false
	while_searching_node.visible = false
	match_found_node.visible = true
	var opponents_name: String = FusionSdk.get_opponents_name()
	if Fusion.is_master_client():
		host_name_label.text = FusionSdk.my_name
		guest_name_label.text = opponents_name
	else:
		host_name_label.text = opponents_name
		guest_name_label.text = FusionSdk.my_name
	
	await get_tree().create_timer(5.0).timeout
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
	disconnected_from_multiplayer.emit()
	


func _on_cancel_searching_button_pressed() -> void:
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
