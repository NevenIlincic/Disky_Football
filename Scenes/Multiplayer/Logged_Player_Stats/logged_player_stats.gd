class_name LoggedPlayerStats extends Node2D

@onready var player_name_label: Label = $Player_Name_Label
@onready var fans_amount_label: Label = $Fans_Amount_Label
@onready var money_amount_label: Label = $Money_Amount_Label
@onready var current_level_label: Label = $Current_Level_Label
@onready var team_name_label: Label = $Team_Name_Label
@onready var edit_team_name_button: TextureButton = $Edit_Team_Name_Button

signal edit_team_name_button_pressed()

func _ready() -> void:
	set_player_stats()

func hide_stats():
	visible = false
	
#DOBAVITI IZ PLAYGAMA SDK
func set_player_stats():
	get_player_name()
	get_fans_amount()
	get_money_amount()
	get_current_level()
	get_player_team_name()

func get_player_name() -> void:
	player_name_label.text = str("COACH: ", FusionSdk.my_name)
func get_fans_amount() -> void:
	fans_amount_label.text = str(100)
func get_money_amount() -> void:
	money_amount_label.text = str(50)
func get_current_level() -> void:
	current_level_label.text = str(14)
func get_player_team_name() -> void:
	team_name_label.text = str("TEAM: ", FusionSdk.my_team_name)

func set_player_team_name(team_name: String) -> void:
	var new_display_name: String = str("TEAM: ", team_name)
	team_name_label.text = new_display_name
	FusionSdk.my_team_name = team_name
	### ODUZETI OVDE NOVAC
	check_has_money_for_team_name_change()
	#PlayGamaSDK.set_team_name()

func check_has_money_for_team_name_change() -> void:
	if 20 > 14:
		edit_team_name_button.visible = true
	else:
		edit_team_name_button.visible = false


func _on_edit_team_name_button_pressed() -> void:
	edit_team_name_button_pressed.emit()
