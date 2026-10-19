class_name LoggedPlayerStats extends Node2D

@onready var player_name_label: Label = $Player_Name_Label
@onready var fans_amount_label: Label = $Fans_Amount_Label
@onready var money_amount_label: Label = $Money_Amount_Label
@onready var current_level_label: Label = $Current_Level_Label

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

func get_player_name() -> void:
	player_name_label.text = "MeXa"
func get_fans_amount() -> void:
	fans_amount_label.text = str(100)
func get_money_amount() -> void:
	money_amount_label.text = str(50)
func get_current_level() -> void:
	current_level_label.text = str(14)
