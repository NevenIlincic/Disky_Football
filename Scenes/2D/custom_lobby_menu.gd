class_name CustomLobbyMenu extends Control

@onready var custom_lobby_label: Label = $Match_Found_Node/Custom_Lobby_Label
@onready var host_name_label: Label = $Match_Found_Node/Host_Name_Label
@onready var guest_name_label: Label = $Match_Found_Node/Guest_Name_Label
@onready var host_team_name_label: Label = $Match_Found_Node/Host_Team_Name_Label
@onready var guest_team_name_label: Label = $Match_Found_Node/Guest_Team_Name_Label
@onready var host_level_label: Label = $Match_Found_Node/Host_Level/Host_Level_Label
@onready var guest_level_label: Label = $Match_Found_Node/Guest_Level_Node/Guest_Level_Label

#HOST FORMATIONS
@onready var _3_3_standard_texture_rect: TextureRect = $"Match_Found_Node/Host_Formations/3-3_Standard_Texture_Rect"
@onready var _3_3_wide_front_texture_rect: TextureRect = $"Match_Found_Node/Host_Formations/3-3_Wide_Front_Texture_Rect"
@onready var _5_1_front_texture_rect: TextureRect = $"Match_Found_Node/Host_Formations/5-1_Front_Texture_Rect"
@onready var _4_2_texture_rect: TextureRect = $"Match_Found_Node/Host_Formations/4-2_Texture_Rect"
@onready var _2_4_texture_rect: TextureRect = $"Match_Found_Node/Host_Formations/2-4_Texture_Rect"
@onready var host_formations: Node2D = $Match_Found_Node/Host_Formations

#GUEST FORMATIONS
@onready var _3_3_standard_texture_rect_guest: TextureRect = $"Match_Found_Node/Guest_Formations/3-3_Standard_Texture_Rect_Guest"
@onready var _3_3_wide_front_texture_rect_guest: TextureRect = $"Match_Found_Node/Guest_Formations/3-3_Wide_Front_Texture_Rect_Guest"
@onready var _5_1_front_texture_rect_guest: TextureRect = $"Match_Found_Node/Guest_Formations/5-1_Front_Texture_Rect_Guest"
@onready var _4_2_texture_rect_guest: TextureRect = $"Match_Found_Node/Guest_Formations/4-2_Texture_Rect_Guest"
@onready var _2_4_texture_rect_guest: TextureRect = $"Match_Found_Node/Guest_Formations/2-4_Texture_Rect_Guest"
@onready var guest_formations: Node2D = $Match_Found_Node/Guest_Formations
@onready var guest_formation_texture_rect: TextureRect = $Match_Found_Node/Guest_Formation_Texture_Rect
@onready var guest_level_node: Node2D = $Match_Found_Node/Guest_Level_Node

var formation_texture_dicts_host: Dictionary
var formation_texture_dicts_guest: Dictionary

#BUTTONS
@onready var start_custom_lobby_button: TextureButton = $Start_Custom_Lobby_Button
@onready var invite_link_button: TextureButton = $Invite_Link_Button

func _exit_tree() -> void:
	if Fusion.room_joined.is_connected(_on_room_joined):
		Fusion.room_joined.disconnect(_on_room_joined)
	if Fusion.room_left.is_connected(_on_room_left):
		Fusion.room_left.disconnect(_on_room_left)
	if Fusion.player_left.is_connected(_on_player_left):
		Fusion.player_left.disconnect(_on_player_left)
	if FusionSdk.player_introduced.is_connected(_on_player_introduced):
		FusionSdk.player_introduced.disconnect(_on_player_introduced)
	if FusionSdk.custom_lobby_full.is_connected(_on_custom_lobby_full):
		FusionSdk.custom_lobby_full.disconnect(_on_custom_lobby_full)


func _ready() -> void:
	Fusion.room_joined.connect(_on_room_joined)
	Fusion.room_left.connect(_on_room_left)
	#Fusion.master_client_changed.connect(_on_master_client_changed)
	Fusion.player_left.connect(_on_player_left)
	FusionSdk.player_introduced.connect(_on_player_introduced)
	FusionSdk.custom_lobby_full.connect(_on_custom_lobby_full)
	if not Fusion.is_master_client():
		start_custom_lobby_button.visible = false
		invite_link_button.visible = false
	
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

func update_lobby():
	var opponents_name: String = FusionSdk.get_opponents_name()
	var opponents_team_name: String = FusionSdk.get_opponents_team_name()
	var opponents_foramtion_id: int = FusionSdk.get_opponents_formation_id()
	var opponents_level: int = FusionSdk.get_opponents_level()
	if Fusion.is_master_client():
		host_name_label.text = FusionSdk.my_name
		guest_name_label.text = str("COACH: ", opponents_name)
		host_team_name_label.text = FusionSdk.my_team_name
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
		guest_name_label.text = FusionSdk.my_name
		host_team_name_label.text = str("TEAM: ", opponents_team_name)
		guest_team_name_label.text = FusionSdk.my_team_name
		host_level_label.text = str(opponents_level)
		guest_level_label.text = str(FusionSdk.current_level)
		
		var formation_id: int = FormationsManager.selected_formation
		var texture_dict_host: TextureRect = formation_texture_dicts_host[opponents_foramtion_id]
		texture_dict_host.visible = true
		var texture_dict_guest: TextureRect = formation_texture_dicts_guest[formation_id]
		texture_dict_guest.visible = true
		
	await get_tree().create_timer(3.0).timeout


func show_host_info_as_host() -> void:
	host_name_label.text = FusionSdk.my_name
	host_team_name_label.text = FusionSdk.my_team_name
	host_level_label.text = str(FusionSdk.current_level)
	var formation_id: int = FormationsManager.selected_formation
	var texture_dict_host: TextureRect = formation_texture_dicts_host[formation_id]
	texture_dict_host.visible = true

func show_guest_info_as_host() -> void:
	var opponents_name: String = FusionSdk.get_opponents_name()
	var opponents_team_name: String = FusionSdk.get_opponents_team_name()
	var opponents_foramtion_id: int = FusionSdk.get_opponents_formation_id()
	var opponents_level: int = FusionSdk.get_opponents_level()
	
	guest_name_label.text = str("COACH: ", opponents_name)
	guest_team_name_label.text = str("TEAM: ", opponents_team_name)
	guest_level_label.text = str(opponents_level)

	var texture_dict_guest: TextureRect = formation_texture_dicts_guest[opponents_foramtion_id]
	texture_dict_guest.visible = true
	
	show_guest_elements()

func show_host_info_as_guest() -> void:
	var opponents_name: String = FusionSdk.get_opponents_name()
	var opponents_team_name: String = FusionSdk.get_opponents_team_name()
	var opponents_formation_id: int = FusionSdk.get_opponents_formation_id()
	var opponents_level: int = FusionSdk.get_opponents_level()
	host_name_label.text = str("COACH: ", opponents_name)
	host_team_name_label.text = str("TEAM: ", opponents_team_name)
	host_level_label.text = str(opponents_level)
	
	var texture_dict_host: TextureRect = formation_texture_dicts_host[opponents_formation_id]
	texture_dict_host.visible = true

func show_guest_info_as_guest()	-> void:
	
	guest_name_label.text = FusionSdk.my_name
	guest_team_name_label.text = FusionSdk.my_team_name
	guest_level_label.text = str(FusionSdk.current_level)
	
	var formation_id: int = FormationsManager.selected_formation
	var texture_dict_guest: TextureRect = formation_texture_dicts_guest[formation_id]
	texture_dict_guest.visible = true
	
	show_guest_elements()

func _on_room_joined() -> void:
	if Fusion.is_master_client():
		show_host_info_as_host()
		start_custom_lobby_button.visible = true
		invite_link_button.visible = true
	else:
		show_guest_info_as_guest()		
		start_custom_lobby_button.visible = false

func _on_room_left() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Multiplayer_Menu_Scene.tscn")
func _on_player_introduced() -> void:
	if Fusion.is_master_client():
		show_guest_info_as_host()
	else:
		show_host_info_as_guest()

func show_guest_elements() -> void:
	guest_level_node.visible = true
	guest_formations.visible = true
	guest_level_label.visible = true
	guest_name_label.visible = true
	guest_team_name_label.visible = true
func hide_guest_elements() -> void:
	guest_level_node.visible = false
	guest_formations.visible = false
	guest_level_label.visible = false
	guest_name_label.visible = false
	guest_team_name_label.visible = false


func _on_player_left(player_id: int, is_inactive: bool) -> void:
	FusionSdk.remove_opponents_data()
	WebSdk.SDK.update_room_status(Fusion.get_room().room_name, true)

	if Fusion.is_master_client():
		FusionSdk.ready_players[FusionSdk.id] = true
		start_custom_lobby_button.visible = true
		start_custom_lobby_button.disabled = true
		
		invite_link_button.visible = true
		invite_link_button.disabled = false
		
		show_host_info_as_host()
		hide_guest_elements()


func _on_custom_lobby_full() -> void:
	start_custom_lobby_button.disabled = false
	invite_link_button.disabled = true


func _on_start_custom_lobby_button_pressed() -> void:
	FusionSdk.match_found.emit()


func _on_leave_custom_lobby_button_pressed() -> void:
	if Fusion.is_in_room():
		FusionSdk.leave_room()
	else:
		_on_room_left()

func _on_start_custom_lobby_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()


func _on_leave_custom_lobby_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()

func _on_invite_link_button_pressed() -> void:
	var room_name: String = Fusion.get_room().room_name
	WebSdk.SDK.generate_invite_url(room_name)
	WebSdk.SDK.copy_invite_url()
