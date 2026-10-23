class_name SkinsPurchasableCard extends PurchasableCard

const CARD_DISPLAY_PLAYER = preload("uid://cws8luontlt5b")

@onready var sub_viewport: SubViewport = $Wrapper/SubViewportContainer/SubViewport

@onready var sub_viewport_container: SubViewportContainer = $Wrapper/SubViewportContainer


func _on_card_id_set(value) -> void:
	set_skin_preview(value)
	update_card_display()
	set_price_tags(value)


func set_skin_preview(id: int):
	var player_skin: CompressedTexture2D = SkinsManager.get_skin_texture_from_id(id)
	var display_player: CardDisplayPlayer = CARD_DISPLAY_PLAYER.instantiate()
	sub_viewport.add_child(display_player)
	display_player.set_skin(player_skin)

func set_price_tags(id: int) -> void:
	fans_price_label.text = str(SkinsManager.get_fans_price_value(id))
	money_price_label.text = str(SkinsManager.get_money_price_value(id))
	
func get_purchased_cards_id() -> Array[int]:
	#ZAMENITI SA PLAYGAMA SDK
	return SkinsManager.get_purchased_skins_ids()

func get_current_selected_card_id() -> int:
	return SkinsManager.get_selected_skin_id()


func _on_select_card_button_pressed(to_save: bool = true) -> void:
	SkinsManager.selected_skin = card_id
	card_selected.emit(card_id)
	if to_save:
		WebSdk.SDK.save_multiplayer_data()

func _handle_card_bought(fans_cost: int, money_cost: int) -> void:
	SkinsManager.purchased_skins_ids.append(card_id)
	_on_select_card_button_pressed(false)
	FusionSdk.handle_fans_and_money_spent(fans_cost, money_cost)
func get_fans_price() -> int:
	return SkinsManager.fans_price[card_id]
func get_money_price() -> int:
	return SkinsManager.money_price[card_id]
