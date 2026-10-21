class_name EffectsPurchasableCard extends PurchasableCard

signal fast_review_enabled(id: int)

var effect_node: ShootEffect
@onready var sub_viewport: SubViewport = $Wrapper/SubViewportContainer/SubViewport

@onready var sub_viewport_container: SubViewportContainer = $Wrapper/SubViewportContainer
@onready var effect_preview_button: TextureButton = $Wrapper/Effect_Preview_Button


func _on_card_id_set(value) -> void:
	set_effect_preview(value)
	update_card_display()
	set_price_tags(value)


func set_effect_preview(id: int):
	effect_node = BallEffects.get_ball_effect_from_id(id)
	sub_viewport.add_child(effect_node)
	effect_node.emitting = true
	slow_down_preview()

func set_price_tags(id: int) -> void:
	fans_price_label.text = str(BallEffects.effects_fans_price[id])
	money_price_label.text = str(BallEffects.effects_money_price[id])

func slow_down_preview():
	effect_node.speed_scale = 0.1

func enable_fast_preview():
	effect_node.speed_scale = 1.5
	fast_review_enabled.emit(card_id)
	
func _on_effect_preview_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		enable_fast_preview()
	else:
		slow_down_preview()

func get_purchased_cards_id() -> Array[int]:
	#ZAMENITI SA PLAYGAMA SDK
	return BallEffects.purchased_effects_id

func get_current_selected_card_id() -> int:
	return BallEffects.selected_effect


func _on_select_card_button_pressed() -> void:
	BallEffects.selected_effect = card_id
	card_selected.emit(card_id)


func _on_buy_button_pressed() -> void:
	super._on_buy_button_pressed()
	#OVO STAVITI U PLAYGAMA SDK DA CUVA
	BallEffects.purchased_effects_id.append(card_id)
	_on_select_card_button_pressed()

func get_fans_price() -> int:
	return BallEffects.effects_fans_price[card_id]
func get_money_price() -> int:
	return BallEffects.effects_money_price[card_id]
