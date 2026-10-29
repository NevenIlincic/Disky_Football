extends Node3D

@onready var main_menu_nodes: Control = $HUD/Main_Menu_Nodes
@onready var team_name_initial_input_node: Node2D = $HUD/Team_Name_Initial_Input_Node
@onready var logged_player_stats: LoggedPlayerStats = $HUD/Main_Menu_Nodes/LoggedPlayerStats
@onready var team_name_input: LineEdit = $HUD/Team_Name_Initial_Input_Node/Team_Name_Input
@onready var label_text: Label = $HUD/Team_Name_Initial_Input_Node/Label_Text
@onready var cancel_button: TextureButton = $HUD/Team_Name_Initial_Input_Node/Cancel_Button
@onready var multiplayer_menu: MultiplayerMenu = $HUD/Main_Menu_Nodes/Multiplayer_Control/MultiplayerMenu
@onready var shop_menu: ShopMenu = $HUD/Main_Menu_Nodes/Control/ShopMenu
@onready var confirmation_dialog_node: Node2D = $HUD/Main_Menu_Nodes/Ad_Node/Confirmation_Dialog_Node
@onready var ad_node: Node2D = $HUD/Main_Menu_Nodes/Ad_Node
@onready var ad_button: TextureButton = $HUD/Main_Menu_Nodes/Ad_Node/Ad_Button

var forbidden_names: Dictionary = {
	"XXX": true,
	"SEX": true
}

var allowed_letters: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

func _exit_tree() -> void:
	if logged_player_stats.edit_team_name_button_pressed.is_connected(_on_edit_team_name_button_pressed):
		logged_player_stats.edit_team_name_button_pressed.disconnect(_on_edit_team_name_button_pressed)
	if multiplayer_menu.search_started.is_connected(_on_match_search_started):
		multiplayer_menu.search_started.disconnect(_on_match_search_started)
	if multiplayer_menu.search_canceled.is_connected(_on_match_search_canceled):
		multiplayer_menu.search_canceled.disconnect(_on_match_search_canceled)
	if WebSdk.SDK.data_loaded.is_connected(_on_data_loaded):
		WebSdk.SDK.data_loaded.disconnect(_on_data_loaded)

func _ready() -> void:	
	logged_player_stats.set_player_stats()
	shop_menu.show_disks_tab()
	
	WebSdk.SDK.data_loaded.connect(_on_data_loaded)
	logged_player_stats.edit_team_name_button_pressed.connect(_on_edit_team_name_button_pressed)
	multiplayer_menu.search_started.connect(_on_match_search_started)
	multiplayer_menu.search_canceled.connect(_on_match_search_canceled)
	multiplayer_menu.custom_lobby_button_pressed.connect(_on_custom_lobby_button_pressed)
	check_is_ad_block_enabled()
	
func check_is_ad_block_enabled() -> void:
	if WebSdk.SDK.check_is_ad_block_enabled():
		ad_button.disabled = true
	else:
		ad_button.disabled = false
		
func _on_data_loaded() -> void:
	check_has_team_name()

func check_has_team_name() -> void:
	if FusionSdk.my_team_name.is_empty():
		team_name_initial_input_node.visible = true
		cancel_button.visible = false
		main_menu_nodes.visible = false
	else:
		team_name_initial_input_node.visible = false
		main_menu_nodes.visible = true

func _on_match_search_started() -> void:
	shop_menu.visible = false
	logged_player_stats.visible = false
	ad_node.visible = false
func _on_match_search_canceled() -> void:
	shop_menu.visible = true
	logged_player_stats.visible = true
	ad_node.visible = true

func _on_confirm_button_pressed() -> void:
	var entered_input: String = team_name_input.text
	entered_input = entered_input.to_upper()
	if forbidden_names.has(entered_input):
		return
	for char: String in entered_input:
		if not allowed_letters.contains(char):
			return
	
	if entered_input.length() == 3 and entered_input != FusionSdk.my_team_name:
		team_name_initial_input_node.visible = false
		main_menu_nodes.visible = true
		logged_player_stats.set_player_team_name(entered_input)

func _on_custom_lobby_button_pressed() -> void:
	team_name_initial_input_node.visible = false
	ad_node.visible = false
	logged_player_stats.visible = false
	shop_menu.visible = false
	
func _on_edit_team_name_button_pressed() -> void:
	team_name_initial_input_node.visible = true
	cancel_button.visible = true
	label_text.visible = false
	main_menu_nodes.visible = false


func _on_cancel_button_pressed() -> void:
	team_name_initial_input_node.visible = false
	main_menu_nodes.visible = true


func _on_ad_button_pressed() -> void:
	confirmation_dialog_node.visible = true


func _on_ad_confirm_button_pressed() -> void:
	#PUSTITI REWARDED VIDEO
	confirmation_dialog_node.visible = false
	WebSdk.SDK.show_rewarded_ad()

func _on_ad_cancel_button_pressed() -> void:
	confirmation_dialog_node.visible = false


func _on_confirm_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()


func _on_cancel_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()


func _on_ad_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()


func _on_ad_confirm_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()


func _on_ad_cancel_button_mouse_entered() -> void:
	AudioManager.play_hover_sound()

		
