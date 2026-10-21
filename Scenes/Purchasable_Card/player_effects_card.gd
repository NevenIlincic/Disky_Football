class_name EffectsPurchasableCard extends Control

signal fast_review_enabled(id: int)

enum CardState{
	SELECTED,
	LOCKED,
	PURCHASABLE,
	AVAILABLE
}

var card_id: int = 0:
	set(value):
		card_id = value
		set_effect_preview(value)
		update_card_display(value)
var effect_node: ShootEffect
@onready var sub_viewport: SubViewport = $Wrapper/SubViewportContainer/SubViewport

@onready var sub_viewport_container: SubViewportContainer = $Wrapper/SubViewportContainer
@onready var effect_preview_button: TextureButton = $Wrapper/Effect_Preview_Button

func set_card_id(id: int):
	card_id = id

func set_effect_preview(id: int):
	effect_node = BallEffects.get_ball_effect_from_id(id)
	sub_viewport.add_child(effect_node)
	effect_node.emitting = true
	slow_down_preview()

func slow_down_preview():
	effect_node.speed_scale = 0.1

func enable_fast_preview():
	effect_node.speed_scale = 1.5
	fast_review_enabled.emit(card_id)

func update_card_display(value):
	pass

func _on_effect_preview_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		enable_fast_preview()
	else:
		slow_down_preview()
