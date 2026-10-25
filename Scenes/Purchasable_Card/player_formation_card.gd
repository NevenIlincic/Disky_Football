class_name FormationsPurchasableCard extends PurchasableCard

@onready var formation_texture_rect: TextureRect = $Formation_Texture_Rect

func _on_card_id_set(value) -> void:
	update_card_display()
	set_price_tags(value)
	set_formation_texture(value)

func set_formation_texture(value) -> void:
	formation_texture_rect.texture = FormationsManager.get_formation_texture_from_id(value)

func set_price_tags(id: int) -> void:
	fans_price_label.text = str(get_fans_price())
	money_price_label.text = str(get_money_price())

func get_fans_price() -> int:
	return FormationsManager.get_fans_price_value(card_id)
func get_money_price() -> int:
	return FormationsManager.get_money_price_value(card_id)

func get_purchased_cards_id() -> Array[int]:
	return FormationsManager.get_purchased_formations_id()
func get_current_selected_card_id() -> int:
	return FormationsManager.get_selected_formation_id()

#func _handle_card_bought(fans_cost: int, money_cost: int) -> void:
	#FormationsManager.purchased_formations_id.append(card_id)
	#_on_select_card_button_pressed(false)
	#FusionSdk.handle_fans_and_money_spent(fans_cost, money_cost)
	#
func _on_select_card_button_pressed(to_save: bool = true) -> void:
	FormationsManager.selected_formation = card_id
	card_selected.emit(card_id)
	if to_save:
		WebSdk.SDK.save_multiplayer_data()

func set_selected_card(id: int) -> void:
	FormationsManager.selected_formation = id
func add_to_purchased_ids_list(id: int) -> void:
	FormationsManager.purchased_formations_id.append(id)
