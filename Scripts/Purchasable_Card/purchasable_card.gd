@abstract
class_name PurchasableCard extends Control

signal card_selected(id: int)

#NODES
@onready var purchase_node: Node2D = $Wrapper/Purchase_Node
@onready var not_purchased_node: Node2D = $Wrapper/Purchase_Node/Not_Purchased_Node
@onready var cant_buy_node: Node2D = $Wrapper/Cant_Buy_Node

@onready var selected_label: Label = $Wrapper/Selected_Label
@onready var select_card_button: TextureButton = $Wrapper/Purchase_Node/Select_Card_Button

@onready var money_price_label: Label = $Wrapper/Purchase_Node/Not_Purchased_Node/Money_Cost_Node/Money_Price_Label
@onready var fans_price_label: Label = $Wrapper/Purchase_Node/Not_Purchased_Node/Fan_Cost_Node/Fans_Price_Label


var card_id: int = 0:
	set(value):
		card_id = value
		_on_card_id_set(value)
@abstract
func _on_card_id_set(value) -> void

@abstract
func set_price_tags(id: int) -> void

func update_card_display():
	var purchased_cards_id: Array[int] = get_purchased_cards_id()
	var current_selected_id: int = get_current_selected_card_id()
	if card_id == current_selected_id:
		show_selected_label()
		hide_not_purchased_elements()
		hide_select_button()
		return
	
	hide_selected_label()
	if purchased_cards_id.has(card_id):
		show_select_button()
		hide_not_purchased_elements()
	else:
		if FusionSdk.fans_amount < get_fans_price() or FusionSdk.money_amount < get_money_price():
			show_cant_but_node()
			hide_select_button()
		else:
			show_not_purchased_elements()
			hide_select_button()
			hide_cant_buy_node()

func set_card_id(id: int):
	card_id = id

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

@abstract
func get_fans_price() -> int

@abstract
func get_money_price() -> int

func _on_buy_button_pressed() -> void:
	var fans_cost: int = get_fans_price()
	var money_cost: int = get_money_price()
	_handle_card_bought(fans_cost, money_cost)

@abstract
func _handle_card_bought(fans_cost: int, money_cost: int) -> void;
	

@abstract
func get_purchased_cards_id() -> Array[int]

@abstract
func get_current_selected_card_id() -> int

@abstract
func _on_select_card_button_pressed(to_save: bool = true) -> void
