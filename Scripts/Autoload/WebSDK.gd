extends Node

signal sdk_initialized()

var SDK: IWebSDK

var is_initial_boot: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#SDK = PlaygamaSDK.new()
	#add_child(SDK)
	#SDK.initialize_sdk()

func initialize_sdk() -> void:
	if is_initial_boot:
		#is_initial_boot = false
		SDK = CrazyGamesSdkClass.new()
		add_child(SDK)
		await SDK.initialize_sdk()
		sdk_initialized.emit()
	else:
		sdk_initialized.emit()
