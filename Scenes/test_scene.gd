class_name SinglePlayerScene extends Node3D

const ENEMY_SCENE = preload("uid://drhkcd78218ty")
const PLAYER_SCENE = preload("uid://d1w5ccem33kle")

const MAX_DRAG_LENGTH: float = 500.0
const MIN_DRAG_LENGTH: float = 35.0
const INDICATOR_LENGTH: float = 5.0

enum MatchState{
	PLAYING,
	WON_ON_TIME,
	WON_BY_GOALS,
	WON_BY_OPPONENT_DISCONNECTION,
	LOST_ON_TIME,
	LOST_BY_GOALS,
	DRAW,
	GAME_SUSPENDED
}
var match_state: MatchState = MatchState.PLAYING

#GOALS
const GOALS_TO_WIN: int = 1

var is_my_turn: bool = true:
	set(value):
		is_my_turn = value
		if value:
			turn_label.text = "YOUR TURN"
		else:
			turn_label.text = "OPPONENT's TURN"

#TIME
var time_passed: float = 0
const MATCH_DURATION: float = 1200

var is_dragging: bool = false
var start_position: Vector2
var end_position: Vector2

var is_action: bool = false

@onready var ball: Ball = $Field/Ball
@onready var ball_spawn_position: Marker3D = $Field/Ball_Spawn_Position

#HUD
@onready var post_match_screen: PostMatchScreen = $HUD/Control/PostMatchScreen
@onready var multiplayer_pause_menu: MultiplayerPauseMenu = $HUD/Control/MultiplayerPauseMenu

var selected_player: Player

var my_spawn_points: Array[Marker3D] = []
var enemy_spawn_points: Array[Marker3D] = []

#HUD
@onready var field: Node3D = $Field
@onready var shooting_indicator: Sprite3D = $HUD/Control/Shooting_Indicator

@onready var indicator_line: Line2D = $HUD/Indicator_Line
@onready var buttons: Node2D = $HUD/Control/Buttons
@onready var kick_button: TextureButton = $HUD/Control/Buttons/Kick_Button
@onready var move_player_button: TextureButton = $HUD/Control/Buttons/Move_Player_Button
@onready var power_bar: TextureProgressBar = $HUD/Control/Power_Bar
@onready var time_label: Label = $HUD/Control/Scoreboard/Time_Label
@onready var my_score_label: Label = $HUD/Control/Scoreboard/My_Score_Label
@onready var enemy_score_label: Label = $HUD/Control/Scoreboard/Enemy_Score_Label
@onready var goal_scored_sprite: Sprite2D = $HUD/Control/Goal_Scored_Node/Goal_Scored_Sprite
@onready var goal_scored_node: Control = $HUD/Control/Goal_Scored_Node
@onready var football_fans: Node2D = $HUD/Control/Goal_Scored_Node/Football_Fans

@onready var my_goal: Goal = $Field/My_Goal
@onready var enemy_goal: Goal = $Field/Enemy_Goal

#AUDIO
@onready var referee_whistle_sound: AudioStreamPlayer = $Referee_Whistle_Sound
@onready var goal_scored_sound: AudioStreamPlayer = $Goal_Scored_Sound

var formation_spawn_positions_host: Dictionary
#HOST
@onready var _3_3_standard_host: Node3D = $"Host_Formations/3-3_Standard_Host"
@onready var _3_3_front_wide_host: Node3D = $"Host_Formations/3-3_Front_Wide_Host"
@onready var _5_1_standard_host: Node3D = $"Host_Formations/5-1_Standard_Host"
@onready var _2_4_standard_host: Node3D = $"Host_Formations/2_4_Standard_Host"
@onready var _4_2_split_host: Node3D = $"Host_Formations/4_2_Split_Host"

#GUEST
var formation_spawn_positions_guest: Dictionary
@onready var _3_3_standard_guest: Node3D = $"Guest_Formations/3-3_Standard_Guest"
@onready var _3_3_front_wide_guest: Node3D = $"Guest_Formations/3-3_Front_Wide_Guest"
@onready var _5_1_standard_guest: Node3D = $"Guest_Formations/5-1_Standard_Guest"
@onready var _2_4_standard_guest: Node3D = $"Guest_Formations/2_4_Standard_Guest"
@onready var _4_2_split_guest: Node3D = $"Guest_Formations/4_2_Split_Guest"


var drag_direction: Vector3

var elements_in_action: int = 0
var num_players: int = 0
var num_enemies: int = 0

var players: Array[Player]
var enemies: Array[Enemy]

var host_spawn_points: Array[Marker3D] = []
var guest_spawn_points: Array[Marker3D] = []

var has_game_started: bool = false

var my_score: int = 0
var enemy_score: int = 0

var is_initial_kick: bool = true

@onready var turn_label: Label = $HUD/Control/Turn_Label
@onready var host_team_name: Label = $HUD/Control/Scoreboard/Host_Team_Name
@onready var guest_team_name: Label = $HUD/Control/Scoreboard/Guest_Team_Name

func _ready() -> void:
	post_match_screen.set_is_singleplayer_match()
	multiplayer_pause_menu.set_is_singleplayer()
	
	indicator_line.visible = false
	
	my_goal.goal_scored.connect(_on_goal_scored)
	enemy_goal.goal_scored.connect(_on_goal_scored)

	ball.finished_move.connect(_on_ball_finished_move)
	ball.continued_move.connect(_on_ball_continued_move)
	
	set_up_team_names()

	
	initialize_formation_dictionaries()
	spawn_players()

func set_up_team_names() -> void:
	if FusionSdk.my_team_name.is_empty():
		host_team_name.text = FusionSdk.get_random_3_letter_string()
	else:
		host_team_name.text = FusionSdk.my_team_name
	guest_team_name.text = FusionSdk.get_random_3_letter_string()

func initialize_formation_dictionaries() -> void:
	formation_spawn_positions_host = {
		0: _3_3_standard_host,
		1: _2_4_standard_host,
		2: _3_3_front_wide_host,
		3: _4_2_split_host,
		4: _5_1_standard_host
	}
	
	formation_spawn_positions_guest = {
		0: _3_3_standard_guest,
		1: _2_4_standard_guest,
		2: _3_3_front_wide_guest,
		3: _4_2_split_guest,
		4: _5_1_standard_guest
	}

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("drag"):
		if selected_player and (selected_player.is_moving or selected_player.is_shooting):
			is_dragging = true
			start_position = get_viewport().get_mouse_position()
			end_position = start_position # bez zastarele vrednosti
			drag_direction = Vector3.ZERO
			#shooting_indicator.visible = true

	if Input.is_action_just_released("drag") and is_dragging:
		is_dragging = false
		calculate_drag_direction()
		#indicator_line.visible = false
		do_action()
		
	if Input.is_action_pressed("pause_menu") and not post_match_screen.visible:
		multiplayer_pause_menu.visible = true
	if Input.is_action_just_released("pause_menu"):
		multiplayer_pause_menu.visible = false

var next_player_id: int = 0
var next_enemy_id: int = 0
func register_player(player: Player) -> void:
	player.player_id = next_player_id
	
	var player_spawn_position: Vector3
	var player_skin_id: int
	player_skin_id = SkinsManager.selected_skin
	player_spawn_position = host_spawn_points[next_player_id].global_position
	player.set_skin(player_skin_id, true)
		
	player.global_position = player_spawn_position
	player.spawn_position = player_spawn_position
		
	player.player_selected.connect(_on_player_selected)
	player.finished_move.connect(_on_player_finished_move)
	player.continued_move.connect(_on_player_continued_move)

	players.append(player)
	num_players += 1
	next_player_id += 1


func register_enemy(enemy: Enemy) -> void:
	enemy.enemy_id = next_enemy_id
	
	var enemy_spawn_position: Vector3
	var enemy_skin_id: int
	enemy_skin_id = WebSdk.SDK.current_selected_level % SkinsManager.skins.size()
	enemy_spawn_position = guest_spawn_points[next_enemy_id].global_position
	enemy.set_skin(enemy_skin_id, false)
	
	enemy.global_position = enemy_spawn_position
	enemy.spawn_position = enemy_spawn_position
		
	enemy.finished_move.connect(_on_enemy_finished_move)
	enemy.continued_move.connect(_on_enemy_continued_move)

	enemies.append(enemy)
	num_enemies += 1
	next_enemy_id += 1

func _process(delta: float) -> void:
	if is_dragging:
		calculate_drag_direction()
		draw_indicator()

func _physics_process(delta: float) -> void:
	if is_action and has_game_started:
		time_passed += delta * 10
	
		var minutes: int = int(time_passed) / 60
		var seconds: int = int(time_passed) % 60
		
		time_label.text = "%02d:%02d" % [minutes, seconds]
	if time_passed > MATCH_DURATION and match_state == MatchState.PLAYING:
		for player: Player in players:
			freeze_entities(player)
		for enemy: Enemy in enemies:
			freeze_entities(enemy)
		freeze_entities(ball)
		handle_match_finished_on_time()

func handle_match_finished_on_time():
	is_action = false
	if my_score == enemy_score:
		match_state = MatchState.DRAW

	elif my_score > enemy_score:
		match_state = MatchState.WON_ON_TIME
	else:
		match_state = MatchState.LOST_ON_TIME
	_on_match_finished()


func freeze_entities(body: RigidBody3D) -> void:
	body.freeze = true
func reset_entities_position():
	match match_state:
		MatchState.PLAYING:
			for player: Player in players:
				player.respawn_entity()

			for enemy: Enemy in enemies:
				enemy.respawn_entity()
			ball.respawn_entity()
			my_goal.reset_entity()
			enemy_goal.reset_entity()
			goal_scored_node.visible = false
			await get_tree().physics_frame

			referee_whistle_sound.play()
			if not is_my_turn:
				await get_tree().create_timer(1.0).timeout
				has_game_started = true
				handle_enemy_turn()
			else:
				has_game_started = true
		_:
			_on_match_finished()
			#if MatchFinishState.FINISHED_NORMAL:
				#FusionSdk.leave_room()


func _on_match_finished():
	goal_scored_node.visible = false
	post_match_screen.visible = true
	
	post_match_screen.do_after_match()


func spawn_players():
	var host_formation_node: Node3D
	var guest_formation_node: Node3D
	host_formation_node = formation_spawn_positions_host[FormationsManager.selected_formation]
	guest_formation_node = formation_spawn_positions_guest[WebSdk.SDK.current_selected_level % FormationsManager.formations.size()]

	for host_player_position: Marker3D in host_formation_node.get_children():
		host_spawn_points.append(host_player_position)
	for guest_player_position: Marker3D in guest_formation_node.get_children():
		guest_spawn_points.append(guest_player_position)
	
	for i in range(0, 12):
		if i <= 5:	
			var player: Player = PLAYER_SCENE.instantiate()
			add_child(player)
		else:
			var enemy: Enemy = ENEMY_SCENE.instantiate()
			add_child(enemy)
	
	
	ball.spawn_position = ball_spawn_position.global_position

	has_game_started = true
	referee_whistle_sound.play()



func _on_enemy_continued_move(_enemy: Enemy):
	_on_move_continued()

func _on_enemy_finished_move(_enemy: Enemy):
	_on_move_finished()

func _on_player_continued_move(_player: Player):
	_on_move_continued()

func _on_ball_continued_move(_ball: Ball):
	_on_move_continued()

func _on_move_continued():
	elements_in_action += 1
	if not is_action:
		is_action = true

func _on_move_finished():
	elements_in_action -= 1

	if elements_in_action <= 0 and is_action:
		is_action = false
		_reset_elements_in_action()
		if not is_my_turn:
			get_tree().create_timer(2.0).timeout.connect(handle_enemy_turn)

func _reset_elements_in_action():
	elements_in_action = 0

func _on_ball_finished_move(_ball: Ball):
	_on_move_finished()

func _on_player_finished_move(_player: Player):
	_on_move_finished()


##DRAG/INDICATOR

func calculate_drag_direction():
	end_position = get_viewport().get_mouse_position()
	drag_direction = Vector3.ZERO
	drag_direction.x = start_position.x - end_position.x
	drag_direction.z = start_position.y - end_position.y
	drag_direction = drag_direction.limit_length(MAX_DRAG_LENGTH)


func draw_indicator():
	if not selected_player:
		indicator_line.visible = false
		return

	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return

	var origin_3d: Vector3
	if selected_player.is_moving:
		origin_3d = selected_player.global_position
	elif selected_player.is_shooting:
		origin_3d = ball.global_position
	else:
		indicator_line.visible = false
		return

	var dir_flat: = Vector3(drag_direction.x, 0.0, drag_direction.z)
	var drag_length: float = dir_flat.length()

	if drag_length < 0.001:
		indicator_line.visible = false
		power_bar.value = 0.0
		return

	var line_length: float = clamp(drag_length / 50.0, 0.1, 10.0)
	var end_3d: Vector3 = origin_3d + dir_flat.normalized() * INDICATOR_LENGTH

	if camera.is_position_behind(origin_3d) or camera.is_position_behind(end_3d):
		indicator_line.visible = false
		return

	indicator_line.visible = true
	indicator_line.clear_points()
	indicator_line.add_point(camera.unproject_position(origin_3d))
	indicator_line.add_point(camera.unproject_position(end_3d))
	
	var power_ratio: float = clamp(drag_length / MAX_DRAG_LENGTH, 0.0, 1.0)

	#power_bar.value = drag_length / 3.0 if drag_length > MIN_DRAG_LENGTH else 0.0
	power_bar.value = power_ratio * power_bar.max_value if drag_length > MIN_DRAG_LENGTH else 0.0

func do_action():
	var drag_length: float = drag_direction.length()

	if drag_length < MIN_DRAG_LENGTH:
		shooting_indicator.visible = false
		power_bar.value = 0.0
		return

	if is_initial_kick:
		is_initial_kick = false
		for player: Player in players:
			player.can_play_sound = true
		for enemy: Enemy in enemies:
			enemy.can_play_sound = true

	ball.has_finished_move = false
	for player: Player in players:
		player.has_finished_move = false

	if selected_player:
		if selected_player.is_moving:
			selected_player.apply_hit_force(drag_direction)
			on_action_done()

		elif selected_player.is_shooting:
			drag_direction.y = sqrt(drag_length) * 3
			ball.apply_hit_force(drag_direction)
			on_action_done()


func on_action_done():
	buttons.visible = false
	power_bar.visible = false
	shooting_indicator.visible = false
	indicator_line.visible = false
	selected_player.on_action_done()
	kick_button.set_pressed_no_signal(false)
	move_player_button.set_pressed_no_signal(false)
	power_bar.value = 0.0
	is_action = true
	selected_player = null
	is_my_turn = false


func _on_player_selected(player: Player):
	if is_action or not is_my_turn:
		return
	if selected_player:
		selected_player.on_player_deselected()
		if selected_player.player_id == player.player_id:
			if not selected_player.is_moving and not selected_player.is_shooting:
				shooting_indicator.visible = false
				indicator_line.visible = false
				selected_player = null
				buttons.visible = false
				power_bar.visible = false
				return
		else:
			kick_button.set_pressed_no_signal(false)
			move_player_button.set_pressed_no_signal(false)

			selected_player.set_player_not_shooting()
			selected_player.set_player_not_moving()

	selected_player = player
	shooting_indicator.global_position = selected_player.global_position
	show_selected_player_elements(selected_player)


func show_selected_player_elements(player: Player):
	if selected_player.is_ball_in_range:
		kick_button.disabled = false
	else:
		kick_button.disabled = true
	buttons.visible = true
	power_bar.visible = true
	selected_player.shooting_area_indicator.visible = true


##ENEMY

func handle_enemy_turn():
	if not has_game_started:
		return
	var is_ball_in_range: bool = false
	var closest_enemy_from_ball: Enemy
	var closest_enemy_distance_from_ball: float = INF
	for enemy: Enemy in enemies:
		if enemy.is_ball_in_range:
			is_ball_in_range = true
			break
		else:
			var distance_from_ball: float = enemy.global_position.distance_to(ball.global_position)
			if distance_from_ball < closest_enemy_distance_from_ball:
				closest_enemy_distance_from_ball = distance_from_ball
				closest_enemy_from_ball = enemy

	var direction: Vector3 = Vector3.ZERO
	direction.x = randf_range(-600, 600.0)
	direction.z = randf_range(-600.0, 600.0)

	if is_ball_in_range: ### SHOOT BALL
		direction.y = sqrt(direction.length()) * 3
		ball.apply_hit_force(direction)
	else: ## MOVE ENEMY
		var intensity_multiplier: int = randi_range(15, 25)
		direction.x = (ball.global_position.x - closest_enemy_from_ball.global_position.x) * intensity_multiplier
		direction.z = (ball.global_position.z - closest_enemy_from_ball.global_position.z) * intensity_multiplier
		direction.y = 0.0
		closest_enemy_from_ball.apply_hit_force(direction)
	is_my_turn = true


#BUTTONS
func _on_kick_button_pressed() -> void:
	if selected_player:
		selected_player.set_player_shooting()

func _on_move_player_button_pressed() -> void:
	if selected_player:
		selected_player.set_player_moving()

func _on_kick_button_toggled(toggled_on: bool) -> void:
	if selected_player:
		if toggled_on:
			selected_player.set_player_shooting()
			move_player_button.set_pressed_no_signal(false)
		else:
			selected_player.set_player_not_shooting()

func _on_move_player_button_toggled(toggled_on: bool) -> void:
	if selected_player:
		if toggled_on:
			selected_player.set_player_moving()
			kick_button.set_pressed_no_signal(false)
		else:
			selected_player.set_player_not_moving()


##GOAL
func _on_goal_scored(goal_owner: Goal.GoalOwner) -> void:
	is_action = false
	has_game_started = false
	goal_scored_node.visible = true
	play_goal_effect()
	play_cheer_effect()

	if goal_owner == Goal.GoalOwner.ME:
		on_enemy_scored()
	else:
		on_scored()

	get_tree().create_timer(3.0).timeout.connect(reset_entities_position)


func play_cheer_effect() -> void:
	for football_fan in football_fans.get_children():
		var tween: Tween = create_tween()
		var start_pos: Vector2 = football_fan.position
		tween.tween_interval(randf_range(0.1, 0.5))
		for i in range(0, 5):
			tween.tween_property(football_fan, "scale", Vector2(1.2, 0.8), 0.1)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

			tween.set_parallel(true)
			tween.tween_property(football_fan, "scale", Vector2(0.85, 1.2), 0.15)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(football_fan, "position:y", start_pos.y - 60, 0.25)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

			tween.set_parallel(false)
			tween.tween_property(football_fan, "position:y", start_pos.y, 0.25)\
				.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			tween.parallel().tween_property(football_fan, "scale", Vector2(1.0, 1.0), 0.25)\
				.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func play_goal_effect() -> void:
	goal_scored_sound.play()
	goal_scored_sprite.visible = true
	goal_scored_sprite.scale = Vector2.ZERO

	var tween := create_tween()
	tween.tween_property(goal_scored_sprite, "scale", Vector2(1.3, 1.3), 1.0)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(goal_scored_sprite, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func on_enemy_scored() -> void:
	enemy_score += 1
	enemy_score_label.text = str(enemy_score)
	if enemy_score < GOALS_TO_WIN:
		is_my_turn = true
	else:
		match_state = MatchState.LOST_BY_GOALS


func on_scored() -> void:
	my_score += 1
	my_score_label.text = str(my_score)
	if my_score < GOALS_TO_WIN:
		is_my_turn = false
	else:
		match_state = MatchState.WON_BY_GOALS
