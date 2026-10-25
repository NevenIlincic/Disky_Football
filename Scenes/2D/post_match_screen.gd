class_name PostMatchScreen extends Control

@onready var you_won_lost_label: Label = $You_Won_Lost_Label
var has_done: bool = false
var scene: Object
var has_leveled_up: bool = false
@onready var level_up_sound: AudioStreamPlayer = $Level_Up_Sound

#PROGRESS BAR
@onready var progress_bar: TextureProgressBar = $Gained_Stats/Progress_Bar/Progress_Bar
@onready var percentage_to_new_level_label: Label = $Gained_Stats/Progress_Bar/Percentage_To_New_Level_Label

#TEXTURE_RECTS
@onready var fan_texture_rect: TextureRect = $Gained_Stats/Fans_Amount_Stats_Node/Fan_Texture_Rect
@onready var money_texture_rect: TextureRect = $Gained_Stats/Money_Amount_Stats_Node/Money_Texture_Rect

#LABELS
@onready var gained_money_label: Label = $Gained_Stats/Money_Amount_Stats_Node/Gained_Money_Label
@onready var gained_fans_label: Label = $Gained_Stats/Fans_Amount_Stats_Node/Gained_Fans_Label
@onready var fans_bonus_amount_label: Label = $Gained_Stats/Level_Up_Bonus_Node/Fans_Bonus_Amount_Label
@onready var money_bonus_amount_label: Label = $Gained_Stats/Level_Up_Bonus_Node/Money_Bonus_Amount_Label
@onready var level_up_label: Label = $Gained_Stats/Level_Up_Bonus_Node/Level_Up_Label

#GAINED STATS NODE
@onready var gained_stats: Control = $Gained_Stats

#BUTTONS
@onready var leave_button: TextureButton = $Leave_Button

#NODES
@onready var level_up_bonus_node: Node2D = $Gained_Stats/Level_Up_Bonus_Node

var gained_experience_map: Dictionary
var match_state: MultiplayerScene.MatchState

var total_money_gained: int = 0
var total_fans_gained: int = 0

var is_singleplayer_match: bool = false

func _exit_tree() -> void:
	if WebSdk.SDK.interstitial_ad_watched.is_connected(_on_interstitial_ad_watched):
		WebSdk.SDK.interstitial_ad_watched.disconnect(_on_interstitial_ad_watched)


func set_is_singleplayer_match():
	gained_stats.visible = false
	is_singleplayer_match = true
	scene = get_tree().get_first_node_in_group("singleplayer_scene") as SinglePlayerScene


func _ready() -> void:
	WebSdk.SDK.interstitial_ad_watched.connect(_on_interstitial_ad_watched)
	leave_button.visible = false
	
	if not is_singleplayer_match:
		scene = get_tree().get_first_node_in_group("multiplayer_scene") as MultiplayerScene
		progress_bar.value = FusionSdk.experience_amount
		progress_bar.max_value = FusionSdk.get_needed_experience_amount_to_level_up()
		var percentage = int((progress_bar.value / progress_bar.max_value) * 100)
		percentage_to_new_level_label.text = str(percentage) + "%"
	
#UZMI EXPERIENCE I LEVEL IGRACA PREKO SDK-a
func _on_interstitial_ad_watched() -> void:
	#SINGLEPLAYER
	if is_singleplayer_match:
		leave_button.visible = true
		if WebSdk.SDK.current_selected_level != WebSdk.SDK.last_unlocked_singleplayer_level:
			return
		if match_state == scene.MatchState.WON_ON_TIME or match_state == scene.MatchState.WON_BY_GOALS:
			if WebSdk.SDK.last_unlocked_singleplayer_level < 21:
				WebSdk.SDK.last_unlocked_singleplayer_level += 1
				WebSdk.SDK.current_selected_level = WebSdk.SDK.last_unlocked_singleplayer_level
				WebSdk.SDK.save_singleplayer_data()
		return
	
	#MULTIPLAYER
	if not (FusionSdk.check_is_max_level() and FusionSdk.experience_amount >= FusionSdk.get_needed_experience_amount_to_level_up()):
		handle_gaining_experience()
	var currency_gained: Array[int] = handle_currency_gained()
	var fans_gained: int = currency_gained[0]
	var money_gained: int = currency_gained[1]
	await handle_animations(fans_gained, money_gained)
	
	FusionSdk.handle_fans_and_money_gained(total_fans_gained, total_money_gained)
	
	#FusionSdk.handle_money_gained(total_money_gained)
	#FusionSdk.handle_fans_gained(total_fans_gained)
	
	leave_button.visible = true

func do_after_match():
	if has_done: return
	match_state = scene.match_state
	has_done = true
	set_won_lost_label_text()
	await get_tree().create_timer(1.0).timeout
	WebSdk.SDK.show_interstitial_ad()
	
	
	#handle_gaining_experience()
	#var currency_gained: Array[int] = handle_currency_gained()
	#var fans_gained: int = currency_gained[0]
	#var money_gained: int = currency_gained[1]
	#await handle_animations(fans_gained, money_gained)
			#
	#FusionSdk.handle_money_gained(total_money_gained)
	#FusionSdk.handle_fans_gained(total_fans_gained)
	#leave_button.visible = true
	#
	

func set_won_lost_label_text():
	match scene.match_state:
		scene.MatchState.DRAW:
			you_won_lost_label.text = str("TIME'S UP! DRAW!\n", scene.my_score, "-", scene.enemy_score)
		scene.MatchState.LOST_ON_TIME:
			you_won_lost_label.text = str("TIME'S UP! YOU LOST!\n", scene.my_score, "-", scene.enemy_score)
		scene.MatchState.LOST_BY_GOALS:
			you_won_lost_label.text = str("YOU LOST!\n", scene.my_score, "-", scene.enemy_score)
		scene.MatchState.WON_ON_TIME:
			you_won_lost_label.text = str("TIME'S UP! YOU WON!\n", scene.my_score, "-", scene.enemy_score)
		scene.MatchState.WON_BY_GOALS:
			you_won_lost_label.text = str("YOU WON!\n", scene.my_score, "-", scene.enemy_score)
		scene.MatchState.WON_BY_OPPONENT_DISCONNECTION:
			you_won_lost_label.text = str("YOU WON!\nOpponent has disconnected!")
		scene.MatchState.GAME_SUSPENDED:
			you_won_lost_label.text = str("GAME SUSPENDED!")
		
func _on_leave_button_pressed() -> void:
	if not is_singleplayer_match:
		if Fusion.is_in_room():
			FusionSdk.leave_room()
		get_tree().change_scene_to_file("res://Scenes/Menus/Multiplayer_Menu_Scene.tscn")
	else:
		FusionSdk.has_disconnected_intentionally = true
		get_tree().change_scene_to_file("res://Scenes/Menus/Menu_Scene.tscn")

func handle_gaining_experience() -> void:
	var experience_gained: int = get_gained_experience()
	
	var experience_left_after_level_up: int = 0
	var current_level_max_value: int = FusionSdk.get_needed_experience_amount_to_level_up()
	
	var current_value: int = FusionSdk.experience_amount
	progress_bar.value = current_value
	
	var new_experience_amount: int = current_value + experience_gained
	
	var finish_destination: int
	
	if new_experience_amount >= current_level_max_value:
		has_leveled_up = true
		if FusionSdk.check_is_max_level():
			FusionSdk.experience_amount = FusionSdk.get_needed_experience_amount_to_level_up()
			finish_destination =  current_level_max_value
		else:
			experience_left_after_level_up = new_experience_amount - current_level_max_value
			FusionSdk.current_level += 1
			finish_destination = current_level_max_value
			FusionSdk.experience_amount = experience_left_after_level_up
	else:
		finish_destination = new_experience_amount
		FusionSdk.experience_amount = new_experience_amount
		
	var total_duration: float = 3.0 
	
	var remaining_distance_first: float = finish_destination - current_value
	var duration: float = (remaining_distance_first / current_level_max_value) * total_duration

	var tween: Tween = create_tween()
	tween.tween_method(
		func(val: float):
			progress_bar.value = val
			var percentage = int((val / progress_bar.max_value) * 100)
			percentage_to_new_level_label.text = str(percentage) + "%",
		progress_bar.value,
		finish_destination,
		duration
	)
	await tween.finished
	
	if has_leveled_up:
		var remaining_distance_second: float = experience_left_after_level_up
		var new_current_level_max_value = FusionSdk.get_needed_experience_amount_to_level_up()
		var duration_two: float = (remaining_distance_second / new_current_level_max_value) * total_duration

		tween = create_tween()
		if FusionSdk.check_is_max_level() and FusionSdk.experience_amount >= FusionSdk.get_needed_experience_amount_to_level_up():
			progress_bar.value = new_current_level_max_value
			experience_left_after_level_up = new_current_level_max_value
		else:
			progress_bar.value = 0
		progress_bar.max_value = new_current_level_max_value
		tween.tween_method(
			func(val: float):
				progress_bar.value = val
				var percentage = int((val / progress_bar.max_value) * 100)
				percentage_to_new_level_label.text = str(percentage) + "%",
			progress_bar.value,
			experience_left_after_level_up,
			duration
		)

func get_gained_experience() -> int:
	var experience_gained: int = 3
	match match_state:
		MultiplayerScene.MatchState.DRAW:
			experience_gained = 1
		MultiplayerScene.MatchState.LOST_ON_TIME:
			experience_gained = 0
		MultiplayerScene.MatchState.LOST_BY_GOALS:
			experience_gained = 0
		MultiplayerScene.MatchState.GAME_SUSPENDED:
			experience_gained = 0
		
	return experience_gained

func handle_currency_gained() -> Array[int]:
	match match_state:
		MultiplayerScene.MatchState.DRAW:
			total_fans_gained += 3
		MultiplayerScene.MatchState.LOST_ON_TIME:
			total_fans_gained += 2
		MultiplayerScene.MatchState.LOST_BY_GOALS:
			total_fans_gained += 1
		MultiplayerScene.MatchState.WON_BY_GOALS:
			total_fans_gained += 2 * abs(scene.my_score - scene.enemy_score) + 3
			total_money_gained += 2
		MultiplayerScene.MatchState.WON_ON_TIME:
			total_fans_gained += 5
			total_money_gained += 1
		MultiplayerScene.MatchState.WON_BY_OPPONENT_DISCONNECTION:
			total_fans_gained += abs(scene.my_score - scene.enemy_score) + 3
			total_money_gained += 1
		MultiplayerScene.MatchState.GAME_SUSPENDED:
			total_fans_gained = 0
			total_money_gained = 0
			
	var fans_gained_base: int = total_fans_gained
	var money_gained_base: int = total_money_gained
	
	gained_fans_label.text = str("+", fans_gained_base)
	gained_money_label.text = str("+", money_gained_base)
	
	return [fans_gained_base, money_gained_base]
	
func handle_level_up_bonus() -> void:
	FusionSdk.handle_money_gained(3 * FusionSdk.current_level)
	FusionSdk.handle_fans_gained(5 * FusionSdk.current_level)

func handle_animations(fans_gained: int, money_gained: int) -> void:
	var tween: Tween = create_tween()
	fan_texture_rect.visible = true
	fan_texture_rect.scale = Vector2.ZERO
	tween.tween_property(fan_texture_rect, "scale", Vector2(1.3, 1.3), 1.0)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(fan_texture_rect, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	tween = create_tween()
	gained_fans_label.visible = true
	gained_fans_label.modulate.a = 0.0
	tween.tween_property(gained_fans_label, "modulate:a", 1.0, 1.0)
	await tween.finished
	
	tween = create_tween()
	money_texture_rect.visible = true
	money_texture_rect.scale = Vector2.ZERO
	tween.tween_property(money_texture_rect, "scale", Vector2(1.3, 1.3), 1.0)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(money_texture_rect, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	tween = create_tween()
	gained_money_label.visible = true
	gained_money_label.modulate.a = 0.0
	tween.tween_property(gained_money_label, "modulate:a", 1.0, 1.0)
	await tween.finished
	
	if has_leveled_up:
		level_up_sound.play()
		total_money_gained += 3 * (FusionSdk.current_level - 1)
		total_fans_gained += 5 * (FusionSdk.current_level - 1)
		fans_bonus_amount_label.text = str("+", 5 * (FusionSdk.current_level - 1))
		money_bonus_amount_label.text = str("+", 3 * (FusionSdk.current_level - 1))
		
		level_up_bonus_node.visible = true		
		tween = create_tween()
		level_up_label.visible = true
		level_up_label.modulate.a = 0.0
		tween.tween_property(level_up_label, "modulate:a", 1.0, 1.0)
		await tween.finished
		tween = create_tween().parallel()
		fans_bonus_amount_label.visible = true
		fans_bonus_amount_label.modulate.a = 0.0
		money_bonus_amount_label.visible = true
		money_bonus_amount_label.modulate.a = 0.0
		tween.tween_property(fans_bonus_amount_label, "modulate:a", 1.0, 1.0)
		tween.tween_property(money_bonus_amount_label, "modulate:a", 1.0, 1.0)
		await tween.finished
