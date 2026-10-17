extends Node3D

#@onready var multiplayer_menu: MultiplayerMenu = $HUD/MultiplayerMenu

#LABELS
@onready var connecting_label: Label = $HUD/Connecting_Label
@onready var multiplayer_menu: MultiplayerMenu = $HUD/Main_Menu_Nodes/Multiplayer_Control/MultiplayerMenu

@onready var buttons_control: Control = $HUD/Main_Menu_Nodes/Buttons_Control
@onready var level_selection_menu: Control = $HUD/Main_Menu_Nodes/Level_Selection_Menu

func _ready() -> void:
	Fusion.connected_to_photon.connect(_on_online_connected)
	multiplayer_menu.disconnected_from_multiplayer.connect(_on_disconnected_from_multiplayer)

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Test_Scene.tscn")

func _on_multiplayer_button_pressed() -> void:
	FusionSdk.connect_to_server()
	connecting_label.visible = true

func _on_online_connected():
	connecting_label.visible = false
	
	hide_main_menu_nodes()
	multiplayer_menu.visible = true

func _on_disconnected_from_multiplayer():
	show_main_menu_nodes()
	multiplayer_menu.visible = false

func hide_main_menu_nodes():
	buttons_control.visible = false
	level_selection_menu.visible = false
func show_main_menu_nodes():
	buttons_control.visible = true
	level_selection_menu.visible = true
