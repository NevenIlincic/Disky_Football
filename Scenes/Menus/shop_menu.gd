extends Node2D

const PLAYER_EFFECTS_CARD = preload("uid://duy1m0sfo276v")

@onready var h_box_container: HBoxContainer = $Cards_Scroll_Container/HBoxContainer

func _ready() -> void:
	for i in range(BallEffects.effects.size()):
		var effects_card: EffectsPurchasableCard = PLAYER_EFFECTS_CARD.instantiate()
		effects_card.fast_review_enabled.connect(_on_fast_preview_enabled)
		h_box_container.add_child(effects_card)
		effects_card.set_card_id(i)
	
	var control_dummy_node: Control = Control.new()
	h_box_container.add_child(control_dummy_node)
	
func _on_fast_preview_enabled(card_id: int):
	for child in h_box_container.get_children():
		if child is not EffectsPurchasableCard:
			continue
		var card: EffectsPurchasableCard = child as EffectsPurchasableCard
		if card.card_id == card_id:
			continue
		card.effect_preview_button.button_pressed = false
