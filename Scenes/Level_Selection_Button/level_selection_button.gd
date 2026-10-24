class_name LevelSelectionButton extends Node2D

@export var level_number: int
@onready var level_number_label: Label = $Level_Number_Label
@onready var level_selection_texture_button: TextureButton = $Level_Selection_Texture_Button

signal button_pressed()

func _ready() -> void:
	WebSdk.SDK.single_player_data_loaded.connect(_on_singleplayer_data_loaded)
	level_number_label.text = str(level_number)


func _on_singleplayer_data_loaded() -> void:
	update_display()
	
func update_display() -> void:
	if level_number > WebSdk.SDK.last_unlocked_singleplayer_level:
		level_selection_texture_button.disabled = true
		return
	if level_number == WebSdk.SDK.current_selected_level:
		level_selection_texture_button.set_pressed_no_signal(true)
		
func _on_level_selection_texture_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		button_pressed.emit()
		WebSdk.SDK.current_selected_level = level_number
