extends Node

var SDK: IWebSDK
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SDK = CrazyGamesSdkClass.new()
	add_child(SDK)
	SDK.initialize_sdk()
	#SDK = PlaygamaSDK.new()
	#add_child(SDK)
	#SDK.initialize_sdk()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
