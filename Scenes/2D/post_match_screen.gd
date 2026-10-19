class_name PostMatchScreen extends Control

@onready var you_won_lost_label: Label = $You_Won_Lost_Label
var has_done: bool = false
var scene: MultiplayerScene

#PROGRESS BAR
@onready var progress_bar: TextureProgressBar = $Gained_Stats/Progress_Bar/Progress_Bar
@onready var percentage_to_new_level_label: Label = $Gained_Stats/Progress_Bar/Percentage_To_New_Level_Label

func _ready() -> void:
	scene = get_tree().get_first_node_in_group("multiplayer_scene")
	var percentage = int((progress_bar.value / progress_bar.max_value) * 100)
	percentage_to_new_level_label.text = str(percentage) + "%"
	
#UZMI EXPERIENCE I LEVEL IGRACA PREKO SDK-a
func do_after_match():
	if has_done: return
	has_done = true
	set_won_lost_label_text()
	await get_tree().create_timer(1.0).timeout
	
	var current_value: float = progress_bar.value
	var max_value: float = progress_bar.max_value

	var total_duration: float = 3.0 

	var remaining_distance: float = max_value - current_value
	var duration: float = (remaining_distance / max_value) * total_duration

	var tween: Tween = create_tween()
	tween.tween_method(
		func(val: float):
			progress_bar.value = val
			var percentage = int((val / progress_bar.max_value) * 100)
			percentage_to_new_level_label.text = str(percentage) + "%",
		progress_bar.value,
		progress_bar.max_value,
		duration
	)


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

func _on_leave_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menus/Multiplayer_Menu_Scene.tscn")
