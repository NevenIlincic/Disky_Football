class_name MultiplayerMenu extends Control

signal disconnected_from_multiplayer()
signal search_started()
signal search_canceled()
signal custom_lobby_button_pressed()
signal instant_multiplayer_activated()

var logged_in_player_stats: LoggedPlayerStats

@onready var not_searching_node: Control = $Not_Searching_Node
@onready var while_searching_node: Control = $While_Searching_Node
@onready var match_found_node: Control = $Match_Found_Node
@onready var create_custom_lobby_node: Control = $Create_Custom_Lobby_Node
@onready var while_waiting_custom_node: Control = $While_Waiting_Custom_Node

@onready var searching_animation_player: AnimationPlayer = $Searching_Animation_Player
#LABELS
@onready var searching_label: Label = $While_Searching_Node/Searching_Label
@onready var host_name_label: Label = $Match_Found_Node/Host_Name_Label
@onready var guest_name_label: Label = $Match_Found_Node/Guest_Name_Label
@onready var host_team_name_label: Label = $Match_Found_Node/Host_Team_Name_Label
@onready var guest_team_name_label: Label = $Match_Found_Node/Guest_Team_Name_Label
@onready var host_level_label: Label = $Match_Found_Node/Host_Level/Host_Level_Label
@onready var guest_level_label: Label = $Match_Found_Node/Guest_Level/Guest_Level_Label

#FORMATIONS TEXTURE RECTS
#HOST
@onready var _3_3_standard_texture_rect: TextureRect = $"Match_Found_Node/Host_Formations/3-3_Standard_Texture_Rect"
@onready var _3_3_wide_front_texture_rect: TextureRect = $"Match_Found_Node/Host_Formations/3-3_Wide_Front_Texture_Rect"
@onready var _5_1_front_texture_rect: TextureRect = $"Match_Found_Node/Host_Formations/5-1_Front_Texture_Rect"
@onready var _4_2_texture_rect: TextureRect = $"Match_Found_Node/Host_Formations/4-2_Texture_Rect"
@onready var _2_4_texture_rect: TextureRect = $"Match_Found_Node/Host_Formations/2-4_Texture_Rect"

#GUEST
@onready var _3_3_standard_texture_rect_guest: TextureRect = $"Match_Found_Node/Guest_Formations/3-3_Standard_Texture_Rect_Guest"
@onready var _3_3_wide_front_texture_rect_guest: TextureRect = $"Match_Found_Node/Guest_Formations/3-3_Wide_Front_Texture_Rect_Guest"
@onready var _5_1_front_texture_rect_guest: TextureRect = $"Match_Found_Node/Guest_Formations/5-1_Front_Texture_Rect_Guest"
@onready var _4_2_texture_rect_guest: TextureRect = $"Match_Found_Node/Guest_Formations/4-2_Texture_Rect_Guest"
@onready var _2_4_texture_rect_guest: TextureRect = $"Match_Found_Node/Guest_Formations/2-4_Texture_Rect_Guest"

########
var formation_texture_dicts_host: Dictionary
var formation_texture_dicts_guest: Dictionary

#INPUTS
@onready var lobby_name_input: LineEdit = $Create_Custom_Lobby_Node/Custom_Lobby_Create_Input_Node/Lobby_Name_Input

@onready var custom_lobby_menu: CustomLobbyMenu = $CustomLobbyMenu

#BUTTONS
@onready var cancel_searching_button: TextureButton = $While_Searching_Node/Cancel_Searching_Button
@onready var join_button: TextureButton = $Not_Searching_Node/Join_Button
@onready var custom_game_button: TextureButton = $Not_Searching_Node/Custom_Game_Button

func _ready() -> void:
	formation_texture_dicts_host = {
		0: _3_3_standard_texture_rect,
		1: _2_4_texture_rect,
		2: _3_3_wide_front_texture_rect,
		3: _4_2_texture_rect,
		4: _5_1_front_texture_rect
	}
	formation_texture_dicts_guest = {
		0: _3_3_standard_texture_rect_guest,
		1: _2_4_texture_rect_guest,
		2: _3_3_wide_front_texture_rect_guest,
		3: _4_2_texture_rect_guest,
		4: _5_1_front_texture_rect_guest
	}
	
	check_is_in_room()
		
	Fusion.register_broadcast_receiver(self)
	Fusion.room_left.connect(_on_search_canceled)
	FusionSdk.match_found.connect(prepare_match_info)
	logged_in_player_stats = get_tree().get_first_node_in_group("logged_player_stats")
	WebSdk.SDK.join_room_requested.connect(_on_join_room_requested)

func check_is_in_room() -> void:
	if Fusion.is_in_room():
		join_button.disabled = true
		custom_game_button.disabled = true
	
func _exit_tree() -> void:
	Fusion.unregister_broadcast_receiver(self)
	if Fusion.room_left.is_connected(_on_search_canceled):
		Fusion.room_left.disconnect(_on_search_canceled)
	if FusionSdk.match_found.is_connected(prepare_match_info):
		FusionSdk.match_found.disconnect(prepare_match_info)
	if WebSdk.SDK.join_room_requested.is_connected(_on_join_room_requested):
		WebSdk.SDK.join_room_requested.disconnect(_on_join_room_requested)

@rpc("any_peer","call_local")
func _on_match_found():
	FusionSdk.pre_match_info_showed.emit()
	custom_lobby_menu.visible = false
	logged_in_player_stats.hide_stats()
	not_searching_node.visible = false
	while_searching_node.visible = false
	while_waiting_custom_node.visible = false
	
	match_found_node.visible = true
	var opponents_name: String = FusionSdk.get_opponents_name()
	var opponents_team_name: String = FusionSdk.get_opponents_team_name()
	var opponents_foramtion_id: int = FusionSdk.get_opponents_formation_id()
	var opponents_level: int = FusionSdk.get_opponents_level()
	if Fusion.is_master_client():
		host_name_label.text = get_my_name()
		guest_name_label.text = str("COACH: ", opponents_name)
		host_team_name_label.text = get_my_team_name()
		guest_team_name_label.text = str("TEAM: ", opponents_team_name)
		host_level_label.text = str(FusionSdk.current_level)
		guest_level_label.text = str(opponents_level)
		
		var formation_id: int = FormationsManager.selected_formation
		var texture_dict_host: TextureRect = formation_texture_dicts_host[formation_id]
		texture_dict_host.visible = true
		var texture_dict_guest: TextureRect = formation_texture_dicts_guest[opponents_foramtion_id]
		texture_dict_guest.visible = true
	else:
		host_name_label.text = str("COACH: ", opponents_name)
		guest_name_label.text = get_my_name()
		host_team_name_label.text = str("TEAM: ", opponents_team_name)
		guest_team_name_label.text = get_my_team_name()
		host_level_label.text = str(opponents_level)
		guest_level_label.text = str(FusionSdk.current_level)
		
		var formation_id: int = FormationsManager.selected_formation
		var texture_dict_host: TextureRect = formation_texture_dicts_host[opponents_foramtion_id]
		texture_dict_host.visible = true
		var texture_dict_guest: TextureRect = formation_texture_dicts_guest[formation_id]
		texture_dict_guest.visible = true
		
	await get_tree().create_timer(3.0).timeout
	if Fusion.is_master_client():
		Fusion.rpc(FusionSdk.start_match)
		Fusion.unregister_broadcast_receiver(self)


func prepare_match_info():
	Fusion.rpc(_on_match_found)

func _on_join_button_pressed() -> void:
	search_started.emit()
	show_while_searching_node()
	FusionSdk.create_quick_match_room()


func _on_back_button_pressed() -> void:
	FusionSdk.has_disconnected_intentionally = true
	Fusion.disconnect_from_photon()
	get_tree().change_scene_to_file("res://Scenes/Menus/Menu_Scene.tscn")
	

func _on_cancel_searching_button_pressed() -> void:
	if Fusion.is_in_room():
		cancel_searching_button.disabled = true
		FusionSdk.leave_room()
		search_canceled.emit()
	else:
		_on_search_canceled()
		search_canceled.emit()
func _on_search_canceled():
	cancel_searching_button.disabled = false
	join_button.disabled = false
	custom_game_button.disabled = false
	show_not_searching_node()
	
func show_not_searching_node():
	searching_label.visible = false
	searching_animation_player.stop()
	not_searching_node.visible = true
	while_searching_node.visible = false
	while_waiting_custom_node.visible = false
	create_custom_lobby_node.visible = false

func show_while_searching_node():
	searching_label.visible = true
	searching_animation_player.play("Searching_Animation")
	not_searching_node.visible = false
	while_searching_node.visible = true
	while_waiting_custom_node.visible = false

func show_while_waiting_node():
	not_searching_node.visible = false
	while_waiting_custom_node.visible = true
	searching_animation_player.play("Waiting_Animation")
	create_custom_lobby_node.visible = false

func get_my_name() -> String:
	#ZAMENI SA PLAYGAMA SDK
	return str("COACH: ", FusionSdk.my_name) 

func get_my_team_name() -> String:
	return str("TEAM: ", FusionSdk.my_team_name)


func _on_join_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()


func _on_back_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()


func _on_cancel_searching_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()


func _on_custom_game_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()


func _on_custom_game_button_pressed() -> void:
	create_custom_lobby_node.visible = true
	not_searching_node.visible = false
	custom_lobby_button_pressed.emit()


func _on_custom_lobby_cancel_button_pressed() -> void:
	_on_cancel_searching_button_pressed()


func _on_custom_lobby_confirm_button_pressed() -> void:
	var room_name: String = lobby_name_input.text
	if room_name.length() == 5:
		FusionSdk.create_or_join_private_room(room_name)
		custom_lobby_menu.visible = true
		not_searching_node.visible = false
		while_waiting_custom_node.visible = false
		create_custom_lobby_node.visible = false

func _on_cancel_waiting_button_pressed() -> void:
	if Fusion.is_in_room():
		FusionSdk.leave_room()
		search_canceled.emit()
	else:
		_on_search_canceled()
		search_canceled.emit()


func _on_custom_lobby_confirm_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()


func _on_custom_lobby_cancel_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()

func check_is_instant_multiplayer_join() -> void:
	#USAO PREKO ISNTANT MULTIPLAYER
	if WebSdk.SDK.is_instant_multiplayer_join:
		WebSdk.SDK.is_instant_multiplayer_join = false
		not_searching_node.visible = false
		while_waiting_custom_node.visible = false
		create_custom_lobby_node.visible = false
		instant_multiplayer_activated.emit()
		custom_lobby_menu.visible = false
		_on_join_button_pressed()
		return
	#USAO PREKO POZIVNOG LINKA (INVITE LINK)
	if not WebSdk.SDK.instant_multiplayer_room_name.is_empty():
		var room_name: String = WebSdk.SDK.instant_multiplayer_room_name
		WebSdk.SDK.instant_multiplayer_room_name = ""
		not_searching_node.visible = false
		while_waiting_custom_node.visible = false
		create_custom_lobby_node.visible = false
		instant_multiplayer_activated.emit()
		if FusionSdk.is_in_private_room:
			custom_lobby_menu.visible = true
		else:
			custom_lobby_menu.visible = false
		FusionSdk.join_instant_multiplayer_room_invite_link(room_name)

func _on_join_room_requested(room_name: String, is_private: bool) -> void:
	FusionSdk.is_in_private_room = is_private
	WebSdk.SDK.instant_multiplayer_room_name = ""
	not_searching_node.visible = false
	while_waiting_custom_node.visible = false
	create_custom_lobby_node.visible = false
	instant_multiplayer_activated.emit()
	if FusionSdk.is_in_private_room:
		custom_lobby_menu.visible = true
	else:
		custom_lobby_menu.visible = false
	FusionSdk.join_instant_multiplayer_room_invite_link(room_name)

		
		
		#FusionSdk.create_or_join_private_room(room_name)
