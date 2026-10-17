extends Node2D

@onready var host_name_label: Label = $Host_Name_Label
@onready var guest_name_label: Label = $Guest_Name_Label
#func _ready() -> void:
	#if Fusion.is_master_client():
		#host_name_label.text = FusionSdk.my_name
		#guest_name_label.text = opponents_name
	#else:
		#host_name_label.text = opponents_name
		#guest_name_label.text = FusionSdk.my_name
