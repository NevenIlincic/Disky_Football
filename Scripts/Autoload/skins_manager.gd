extends Node

const PLAYER_SKIN_0 = preload("uid://gut4l02itfay")
const PLAYER_SKIN_1 = preload("uid://d4c5ye646wjsi")
const PLAYER_SKIN_2 = preload("uid://dn0t7t4y78hlv")
const PLAYER_SKIN_3 = preload("uid://bqyypc6qoxnrr")
const PLAYER_SKIN_4 = preload("uid://8qh23ijkbja8")
const PLAYER_SKIN_5 = preload("uid://dp1btyirbn2i5")
const PLAYER_SKIN_6 = preload("uid://ccbhwpvm4q12v")
const PLAYER_SKIN_7 = preload("uid://bmeqwvqulqee8")

var selected_skin: int = 0

var purchased_skins_ids: Array[int] = [0]

var skins: Dictionary = {
	0: PLAYER_SKIN_0, #Orange
	1: PLAYER_SKIN_1, #Blue
	2: PLAYER_SKIN_2, #Green
	3: PLAYER_SKIN_3,
	4: PLAYER_SKIN_4,
	5: PLAYER_SKIN_5,
	6: PLAYER_SKIN_6,
	7: PLAYER_SKIN_7
}

var fans_price: Dictionary = {
	0: 0,
	1: 5,
	2: 10,
	3: 14,
	4: 12,
	5: 15,
	6: 17,
	7: 20
}
var money_price: Dictionary = {
	0: 0,
	1: 3,
	2: 6,
	3: 8,
	4: 10,
	5: 15,
	6: 11,
	7: 15
}

func get_skin_texture_from_id(id: int) -> CompressedTexture2D:
	var skin_texture: CompressedTexture2D = skins[id]
	return skin_texture

func get_fans_price_value(id: int) -> int:
	return fans_price[id]
func get_money_price_value(id: int) -> int:
	return money_price[id]
func get_purchased_skins_ids() -> Array[int]:
	return purchased_skins_ids
func get_selected_skin_id() -> int:
	return selected_skin
