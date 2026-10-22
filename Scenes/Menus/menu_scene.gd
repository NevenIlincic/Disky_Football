extends Node3D

#@onready var multiplayer_menu: MultiplayerMenu = $HUD/MultiplayerMenu

#LABELS
@onready var connecting_label: Label = $HUD/Connecting_Label
@onready var multiplayer_menu: MultiplayerMenu = $HUD/Main_Menu_Nodes/Multiplayer_Control/MultiplayerMenu

@onready var buttons_control: Control = $HUD/Main_Menu_Nodes/Buttons_Control
@onready var level_selection_menu: Control = $HUD/Main_Menu_Nodes/Level_Selection_Menu

func _ready() -> void:
	Fusion.connected_to_photon.connect(_on_online_connected)
	Fusion.connection_failed.connect(_on_connection_failed)
	multiplayer_menu.disconnected_from_multiplayer.connect(_on_disconnected_from_multiplayer)
	
	if FusionSdk.has_connection_lost and not FusionSdk.has_disconnected_intentionally:
		connecting_label.visible = true
		connecting_label.text = "Lost connection with the server! Try again!"
		await get_tree().create_timer(3.0).timeout
		connecting_label.visible = false
		
func _exit_tree() -> void:
	if Fusion.connected_to_photon.is_connected(_on_online_connected):
		Fusion.connected_to_photon.disconnect(_on_online_connected)
	if Fusion.connection_failed.is_connected(_on_connection_failed):
		Fusion.connection_failed.disconnect(_on_connection_failed)

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Test_Scene.tscn")

func _on_multiplayer_button_pressed() -> void:
	FusionSdk.connect_to_server()
	connecting_label.text = "Connecting..."
	connecting_label.visible = true

func _on_online_connected():
	FusionSdk.has_disconnected_intentionally = false
	get_tree().change_scene_to_file("res://Scenes/Menus/Multiplayer_Menu_Scene.tscn")
	#connecting_label.visible = false
	#
	#hide_main_menu_nodes()
	#multiplayer_menu.visible = true

func _on_connection_failed() -> void:
	connecting_label.text = "Unable to connect. Try again later!"
	connecting_label.visible = true
	await get_tree().create_timer(2.0).timeout
	connecting_label.visible = false
func _on_disconnected_from_multiplayer():
	show_main_menu_nodes()
	multiplayer_menu.visible = false

func hide_main_menu_nodes():
	buttons_control.visible = false
	level_selection_menu.visible = false
func show_main_menu_nodes():
	buttons_control.visible = true
	level_selection_menu.visible = true
