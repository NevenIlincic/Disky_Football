class_name ShootEffect extends GPUParticles3D

@onready var smoke_effect: GPUParticles3D = $Smoke_Effect

func _ready() -> void:
	stop_effects()

func emit_effects():
	amount = 30
	smoke_effect.amount = 15
	emitting = true
	smoke_effect.emitting = true

func stop_effects():
	emitting = false
	smoke_effect.emitting = false

func reduce_amount():
	amount = 5
	smoke_effect.amount = 5
