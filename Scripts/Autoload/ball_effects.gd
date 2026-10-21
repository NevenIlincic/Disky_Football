extends Node

var selected_effect: int = 4

const BALL_EFFECT_BLUE = preload("uid://bdei36v5vo73t")
const BALL_EFFECT_GREEN = preload("uid://bg5ytrclb4to4")
const BALL_EFFECT_ORANGE = preload("uid://cl7fbi115tehh")
const BALL_EFFECT_PINK = preload("uid://dqeiu6hdd78uk")
const BALL_EFFECT_YELLOW_BLUE = preload("uid://8f858oo6iuji")

var effects: Dictionary = {
	0: BALL_EFFECT_ORANGE, #Orange
	1: BALL_EFFECT_BLUE, #Blue
	2: BALL_EFFECT_GREEN, #Green
	3: BALL_EFFECT_PINK,
	4: BALL_EFFECT_YELLOW_BLUE
}


func get_ball_effect() -> ShootEffect:
	var ball_effect: ShootEffect = effects[selected_effect].instantiate()
	return ball_effect

func get_ball_effect_from_id(id: int) -> ShootEffect:
	var ball_effect: ShootEffect = effects[id].instantiate()
	return ball_effect
