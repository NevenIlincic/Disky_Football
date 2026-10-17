extends Node2D

@onready var host_name_label: Label = $Host_Name_Label
@onready var guest_name_label: Label = $Guest_Name_Label
var opponents_name: String
func _ready() -> void:
	get_opponents_name()
	
	if Fusion.is_master_client():
		host_name_label.text = FusionSdk.my_name
		guest_name_label.text = opponents_name
	else:
		host_name_label.text = opponents_name
		guest_name_label.text = FusionSdk.my_name


func get_opponents_name():
	for player_id: String in FusionSdk.names:
		if player_id != FusionSdk.id:
			opponents_name = FusionSdk.names[player_id]
			break
