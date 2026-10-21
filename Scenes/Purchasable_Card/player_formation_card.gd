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

func _on_buy_button_pressed() -> void:
	super._on_buy_button_pressed()
	FormationsManager.purchased_formations_id.append(card_id)
	_on_select_card_button_pressed()
	
func _on_select_card_button_pressed() -> void:
	FormationsManager.selected_formation = card_id
	card_selected.emit(card_id)
