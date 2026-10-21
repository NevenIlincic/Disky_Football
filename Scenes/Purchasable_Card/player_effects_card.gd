class_name EffectsPurchasableCard extends Control

signal fast_review_enabled(id: int)
signal effect_selected(id: int)
signal effect_bought(id: int)


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
		update_card_display()
		set_price_tags(value)
var effect_node: ShootEffect
@onready var sub_viewport: SubViewport = $Wrapper/SubViewportContainer/SubViewport

@onready var sub_viewport_container: SubViewportContainer = $Wrapper/SubViewportContainer
@onready var effect_preview_button: TextureButton = $Wrapper/Effect_Preview_Button
#NODES
@onready var purchase_node: Node2D = $Wrapper/Purchase_Node
@onready var not_purchased_node: Node2D = $Wrapper/Purchase_Node/Not_Purchased_Node
@onready var cant_buy_node: Node2D = $Wrapper/Cant_Buy_Node

@onready var selected_label: Label = $Wrapper/Selected_Label
@onready var select_card_button: TextureButton = $Wrapper/Purchase_Node/Select_Card_Button

@onready var money_price_label: Label = $Wrapper/Purchase_Node/Not_Purchased_Node/Money_Cost_Node/Money_Price_Label
@onready var fans_price_label: Label = $Wrapper/Purchase_Node/Not_Purchased_Node/Fan_Cost_Node/Fans_Price_Label

func set_card_id(id: int):
	card_id = id



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

func update_card_display():
	var purchased_effects_id: Array[int] = get_purchased_effects_id()
	var current_selected_id: int = get_current_selected_effect_id()
	if card_id == current_selected_id:
		show_selected_label()
		hide_not_purchased_elements()
		hide_select_button()
		return
	
	hide_selected_label()
	if purchased_effects_id.has(card_id):
		show_select_button()
		hide_not_purchased_elements()
	else:
		if FusionSdk.fans_amount < get_fans_price() or FusionSdk.money_amount < get_money_price():
			show_cant_but_node()
		else:
			show_not_purchased_elements()
			hide_select_button()
			hide_cant_buy_node()
	
func _on_effect_preview_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		enable_fast_preview()
	else:
		slow_down_preview()

func get_purchased_effects_id() -> Array[int]:
	#ZAMENITI SA PLAYGAMA SDK
	return BallEffects.purchased_effects_id

func get_current_selected_effect_id() -> int:
	return BallEffects.selected_effect

func hide_purchased_elements() -> void:
	purchase_node.visible = false
func show_purchased_elements() -> void:
	purchase_node.visible = true
func hide_selected_label() -> void:
	selected_label.visible = false
func show_selected_label() -> void:
	selected_label.visible = true

func show_select_button() -> void:
	select_card_button.visible = true
func hide_select_button() -> void:
	select_card_button.visible = false

func show_not_purchased_elements() -> void:
	not_purchased_node.visible = true
func hide_not_purchased_elements() -> void:
	not_purchased_node.visible = false
func show_cant_but_node() -> void:
	cant_buy_node.visible = true
func hide_cant_buy_node() -> void:
	cant_buy_node.visible = false	


func _on_select_card_button_pressed() -> void:
	BallEffects.selected_effect = card_id
	effect_selected.emit(card_id)


func _on_buy_button_pressed() -> void:
	var fans_cost: int = get_fans_price()
	var money_cost: int = get_money_price()
	FusionSdk.handle_money_spend(money_cost)
	FusionSdk.handle_fans_spend(fans_cost)
	#OVO STAVITI U PLAYGAMA SDK DA CUVA
	BallEffects.purchased_effects_id.append(card_id)
	_on_select_card_button_pressed()

func get_fans_price() -> int:
	return BallEffects.effects_fans_price[card_id]
func get_money_price() -> int:
	return BallEffects.effects_money_price[card_id]
