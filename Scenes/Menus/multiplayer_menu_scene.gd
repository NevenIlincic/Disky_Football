extends Node3D

@onready var main_menu_nodes: Control = $HUD/Main_Menu_Nodes
@onready var team_name_initial_input_node: Node2D = $HUD/Team_Name_Initial_Input_Node
@onready var logged_player_stats: LoggedPlayerStats = $HUD/Main_Menu_Nodes/LoggedPlayerStats
@onready var team_name_input: LineEdit = $HUD/Team_Name_Initial_Input_Node/Team_Name_Input
@onready var label_text: Label = $HUD/Team_Name_Initial_Input_Node/Label_Text
@onready var cancel_button: TextureButton = $HUD/Team_Name_Initial_Input_Node/Cancel_Button
@onready var multiplayer_menu: MultiplayerMenu = $HUD/Main_Menu_Nodes/Multiplayer_Control/MultiplayerMenu
@onready var shop_menu: ShopMenu = $HUD/Main_Menu_Nodes/ShopMenu

var forbidden_names: Dictionary = {
	"XXX": true,
	"SEX": true
}

func _exit_tree() -> void:
	if logged_player_stats.edit_team_name_button_pressed.is_connected(_on_edit_team_name_button_pressed):
		logged_player_stats.edit_team_name_button_pressed.disconnect(_on_edit_team_name_button_pressed)



func _ready() -> void:
	check_has_team_name()
	logged_player_stats.edit_team_name_button_pressed.connect(_on_edit_team_name_button_pressed)
func check_has_team_name() -> void:
	if FusionSdk.my_team_name.is_empty():
		team_name_initial_input_node.visible = true
		cancel_button.visible = false
		main_menu_nodes.visible = false
	else:
		team_name_initial_input_node.visible = false
		main_menu_nodes.visible = true


func _on_confirm_button_pressed() -> void:
	var entered_input: String = team_name_input.text
	entered_input = entered_input.to_upper()
	if forbidden_names.has(entered_input):
		return
	if entered_input.length() == 3 and entered_input != FusionSdk.my_team_name:
		team_name_initial_input_node.visible = false
		main_menu_nodes.visible = true
		logged_player_stats.set_player_team_name(entered_input)
		
func _on_edit_team_name_button_pressed() -> void:
		team_name_initial_input_node.visible = true
		cancel_button.visible = true
		label_text.visible = false
		main_menu_nodes.visible = false


func _on_cancel_button_pressed() -> void:
	team_name_initial_input_node.visible = false
	main_menu_nodes.visible = true
