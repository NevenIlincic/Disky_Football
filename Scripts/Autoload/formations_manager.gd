extends Node

const FORMATION_3_3_STANDARD = preload("uid://jgqd4m3he6q1")
const FORMATION_2_4_STANDARD = preload("uid://dwx3bnt25gnsh")
const FORMATION_3_3_FRONT_WIDE = preload("uid://bx2j72g7bmg0l")
const FORMATION_4_2_SPLIT = preload("uid://ddnt76csk8gvq")
const FORMATION_5_1 = preload("uid://bkas74x6dtkke")


var selected_formation: int = 0

var purchased_formations_id: Array[int] = [0]

var formations: Dictionary = {
	0: FORMATION_3_3_STANDARD, #Orange
	1: FORMATION_2_4_STANDARD, #Blue
	2: FORMATION_3_3_FRONT_WIDE, #Green
	3: FORMATION_4_2_SPLIT,
	4: FORMATION_5_1
}

var fans_price: Dictionary = {
	0: 0,
	1: 25,
	2: 30,
	3: 50,
	4: 40
}
var money_price: Dictionary = {
	0: 0,
	1: 40,
	2: 50,
	3: 30,
	4: 50
}

func get_formation_texture_from_id(id: int) -> CompressedTexture2D:
	var formation_texture: CompressedTexture2D = formations[id]
	return formation_texture

func get_fans_price_value(id: int) -> int:
	return fans_price[id]
func get_money_price_value(id: int) -> int:
	return money_price[id]
func get_purchased_formations_id() -> Array[int]:
	return purchased_formations_id
func get_selected_formation_id() -> int:
	return selected_formation
