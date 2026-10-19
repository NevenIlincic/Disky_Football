extends Node3D

@onready var main_menu_nodes: Control = $HUD/Main_Menu_Nodes
@onready var team_name_initial_input_node: Node2D = $HUD/Team_Name_Initial_Input_Node
@onready var logged_player_stats: LoggedPlayerStats = $HUD/Main_Menu_Nodes/LoggedPlayerStats
@onready var team_name_input: LineEdit = $HUD/Team_Name_Initial_Input_Node/Team_Name_Input

var forbidden_names: Dictionary = {
	"XXX": true,
	"SEX": true
}

func _ready() -> void:
	check_has_team_name()
	
func check_has_team_name() -> void:
	if FusionSdk.my_team_name.is_empty():
		team_name_initial_input_node.visible = true
		main_menu_nodes.visible = false
	else:
		team_name_initial_input_node.visible = false
		main_menu_nodes.visible = true


func _on_confirm_button_pressed() -> void:
	var entered_input: String = team_name_input.text
	entered_input = entered_input.to_upper()
	if forbidden_names.has(entered_input):
		return
	if entered_input.length() == 3:
		team_name_initial_input_node.visible = false
		main_menu_nodes.visible = true
		logged_player_stats.set_player_team_name(entered_input)
		
