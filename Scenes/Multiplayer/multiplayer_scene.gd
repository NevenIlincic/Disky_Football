class_name MultiplayerScene extends Node3D

const PLAYER_SCENE = preload("uid://bop3seu5ydqe1")
const BALL_SCENE = preload("res://Scenes/Ball/MultiplayerBall.tscn")
@onready var fusion_spawner: FusionSpawner = $FusionSpawner


var is_my_turn: bool = true

#TIME
var time_passed: float = 0

var is_dragging: bool = false
var start_position: Vector2
var end_position: Vector2

var is_action: bool = false

#@onready var player: Player = $Player
@onready var ball_spawn_position: Marker3D = $Field/Ball_Spawn_Position


var selected_player: MultiplayerPlayer



#@onready var shooting_indicator: Sprite3D = $Shooting_Indicator

#HUD BUTTONS
#@onready var buttons: Node2D = $HUD/Buttons
#@onready var kick_button: Button = $HUD/Buttons/Kick_Button
#@onready var move_player_button: Button = $HUD/Buttons/Move_Player_Button
#@onready var power_bar: TextureProgressBar = $HUD/Power_Bar
@onready var field: Node3D = $Field
@onready var shooting_indicator: Sprite3D = $HUD/Control/Shooting_Indicator
@onready var buttons: Node2D = $HUD/Control/Buttons
@onready var kick_button: TextureButton = $HUD/Control/Buttons/Kick_Button
@onready var move_player_button: TextureButton = $HUD/Control/Buttons/Move_Player_Button
@onready var power_bar: TextureProgressBar = $HUD/Control/Power_Bar
@onready var time_label: Label = $HUD/Control/Scoreboard/Time_Label

var drag_direction: Vector3

var elements_in_action: int = 0
var num_players: int = 0
var num_enemies: int = 0

var multiplayer_players: Array[MultiplayerPlayer]
var host_spawn_points: Array[Marker3D] = []
var guest_spawn_points: Array[Marker3D] = []

var has_game_started: bool = false

var my_score: int = 0
var enemy_score: int = 0
@onready var my_score_label: Label = $HUD/Control/Scoreboard/My_Score_Label
@onready var enemy_score_label: Label = $HUD/Control/Scoreboard/Enemy_Score_Label
@onready var goal_scored_sprite: Sprite2D = $HUD/Control/Goal_Scored_Node/Goal_Scored_Sprite

@onready var my_goal: Goal = $Field/My_Goal
@onready var enemy_goal: Goal = $Field/Enemy_Goal

var is_initial_kick: bool = true

var ball: MultiplayerBall

#AUDIO
@onready var referee_whistle_sound: AudioStreamPlayer = $Referee_Whistle_Sound
@onready var goal_scored_sound: AudioStreamPlayer = $Goal_Scored_Sound

var loaded_peers := {}
var field_spawned := false

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("drag"):
		if selected_player and (selected_player.is_moving or selected_player.is_shooting):
			is_dragging = true
			start_position = get_viewport().get_mouse_position()
			shooting_indicator.visible = true
			
	if Input.is_action_just_released("drag"):
		is_dragging = false
		do_action()



func reset_entities_position():
	for player: MultiplayerPlayer in multiplayer_players:
		player.respawn_entity()

	ball.respawn_entity()
	my_goal.reset_entity()
	enemy_goal.reset_entity()
	goal_scored_node.visible = false
	await get_tree().physics_frame
	
	referee_whistle_sound.play()
	if not is_my_turn:
		await get_tree().create_timer(1.0).timeout
		has_game_started = true
		#handle_enemy_turn()
	else:
		has_game_started = true
		
		
func spawn_players():
	for i in range(0, 12):
		var player = fusion_spawner.spawn(PLAYER_SCENE)
		
		if i <= 5:
			player.is_owner_host = true
			
	for host_spawn_point in get_tree().get_nodes_in_group("host_spawn_point"):
		host_spawn_points.append(host_spawn_point)
	for guest_spawn_point in get_tree().get_nodes_in_group("guest_spawn_point"):
		guest_spawn_points.append(guest_spawn_point)
	
	for i in range(0, multiplayer_players.size()):
		var player: MultiplayerPlayer = multiplayer_players[i]
		var player_spawn_position: Vector3
		if i <= 5:
			player_spawn_position = host_spawn_points[i].global_position
		else:
			player_spawn_position = guest_spawn_points[i - 6].global_position
		
		multiplayer_players[i].global_position = player_spawn_position
		multiplayer_players[i].spawn_position = player_spawn_position


func register_player(player: MultiplayerPlayer) -> void:
	multiplayer_players.append(player)
	num_players += 1
	player.player_selected.connect(_on_player_selected)
	if Fusion.is_master_client():
		player.finished_move.connect(_on_player_finished_move)
		player.continued_move.connect(_on_player_continued_move)

func register_ball(b: MultiplayerBall) -> void:
	ball = b
	if Fusion.is_master_client():
		ball.finished_move.connect(_on_ball_finished_move)
		ball.continued_move.connect(_on_ball_continued_move)
		

func spawn_ball():
	ball = fusion_spawner.spawn(BALL_SCENE)
	#var ball_spawn_position: Vector3 = ball_spawn_position.global_position
	ball.position = ball_spawn_position.position
	print(ball_spawn_position.position)
	ball.spawn_position = ball.global_position

func _enter_tree() -> void:
	Fusion.register_broadcast_receiver(self)


func _ready() -> void:	
	fusion_spawner.add_spawnable_scene(PLAYER_SCENE)
	fusion_spawner.add_spawnable_scene(BALL_SCENE)
	fusion_spawner.spawned.connect(func(n): print("[spawned] ", n.name, " master=", Fusion.is_master_client()))

	child_entered_tree.connect(func(n): print("[child] ", n.name))
	my_goal.goal_scored.connect(_on_goal_scored)
	enemy_goal.goal_scored.connect(_on_goal_scored)
	
	await get_tree().process_frame
	var my_id = FusionSdk.id
	if Fusion.is_master_client():
		peer_scene_ready(my_id)
	else:
		Fusion.rpc_to(Fusion.TARGET_MASTER, peer_scene_ready, my_id)
	has_game_started = true
	referee_whistle_sound.play()
	
@rpc("any_peer", "call_local")
func peer_scene_ready(pid: String) -> void:
	if not Fusion.is_master_client() or field_spawned:
		return
	loaded_peers[pid] = true
	if loaded_peers.size() == 2:
		field_spawned = true
		spawn_field()
		
func spawn_field():
	spawn_ball()
	await get_tree().physics_frame
	#spawn_players()

func _on_enemy_continued_move(enemy: Enemy):
	_on_move_continued()

func _on_enemy_finished_move(enemy: Enemy):
	_on_move_finished()

func _on_player_continued_move(player: MultiplayerPlayer):
	_on_move_continued()	
func _on_ball_continued_move(ball: MultiplayerBall):
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
		#if not is_my_turn:
			#await get_tree().create_timer(2.0).timeout.connect(handle_enemy_turn)
	
func _reset_elements_in_action():
	elements_in_action = 0


func _on_ball_finished_move(ball: Ball):
	_on_move_finished()
	#elements_in_action -= 1
	#if elements_in_action <= 0 and is_action:
		#is_action = false
		#_reset_elements_in_action()

func _on_player_finished_move(player: Player):
	_on_move_finished()

func _process(delta: float) -> void:
	if is_action and has_game_started:
		time_passed += delta * 10
	
		var minutes: int = int(time_passed) / 60
		var seconds: int = int(time_passed) % 60
		
		time_label.text = "%02d:%02d" % [minutes, seconds]
	if is_dragging:
		calculate_drag_direction()
		draw_indicator()

func draw_indicator():
	if not selected_player:
		return
	var drag_distance: Vector2 = start_position - get_viewport().get_mouse_position()
	var current_length = max(drag_distance.length() / 50.0, 0.1)
	var angle = atan2(drag_distance.x, drag_distance.y)
	var offset_height = Vector3(0, 0, 0)
	
	if selected_player.is_moving:
		shooting_indicator.global_position = selected_player.global_position + offset_height
	elif selected_player.is_shooting:
		shooting_indicator.global_position = ball.global_position + offset_height

	shooting_indicator.rotation.y = angle
	shooting_indicator.rotation.z = 0
	var drag_distance_length: float = drag_distance.length()
	if drag_distance_length > 35.0:
		power_bar.value = drag_distance_length / 3.0
	else:
		power_bar.value = 0.0

func calculate_drag_direction():
	end_position = get_viewport().get_mouse_position()
	drag_direction = Vector3.ZERO
	drag_direction.x = start_position.x - end_position.x
	drag_direction.z = start_position.y - end_position.y

func do_action():	
	var drag_distance: Vector2 = start_position - end_position
	if drag_distance.length() < 35.0:
		return
	if is_initial_kick:
		is_initial_kick = false
		for player: MultiplayerPlayer in multiplayer_players:
			player.can_play_sound = true
	ball.has_finished_move = false
	for player: MultiplayerPlayer in multiplayer_players:
		player.has_finished_move = false
	
		
	if selected_player:
		if selected_player.is_moving:
			selected_player.apply_hit_force(drag_direction)
			selected_player.on_action_done()
			on_action_done()

		elif selected_player.is_shooting:
			drag_direction.y = sqrt(drag_distance.length()) * 3
			ball.apply_hit_force(drag_direction)
			on_action_done()
		
func on_action_done():
	buttons.visible = false
	power_bar.visible = false
	shooting_indicator.visible = false
	selected_player.on_action_done()
	kick_button.set_pressed_no_signal(false)
	move_player_button.set_pressed_no_signal(false)
	power_bar.value = 0.0
	is_action = true
	selected_player = null
	is_my_turn = false
	
func _on_player_selected(player: MultiplayerPlayer):
	if is_action or not is_my_turn:
		return
	if selected_player:
		selected_player.on_player_deselected()
		if selected_player.player_id == player.player_id: 
			if not selected_player.is_moving and not selected_player.is_shooting:
				shooting_indicator.visible = false
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


func show_selected_player_elements(player: MultiplayerPlayer):
	if selected_player.is_ball_in_range:
		kick_button.disabled = false
	else:
		kick_button.disabled = true
	buttons.visible = true
	power_bar.visible = true
	selected_player.shooting_area_indicator.visible = true

#func handle_enemy_turn():
	#if not has_game_started:
		#return
	#print("OVDE")
	#var is_ball_in_range: bool = false
	#var closest_enemy_from_ball: Enemy
	#var closest_enemy_distance_from_ball: float = INF
	#for enemy: Enemy in enemies:
		#if enemy.is_ball_in_range:
			#is_ball_in_range = true
			#break
		#else:
			#var distance_from_ball: float = enemy.global_position.distance_to(ball.global_position)
			#if distance_from_ball < closest_enemy_distance_from_ball:
				#closest_enemy_distance_from_ball = distance_from_ball
				#closest_enemy_from_ball = enemy
	#
	#
	#var direction: Vector3 = Vector3.ZERO
	#direction.x = randf_range(-600, 600.0)
	#direction.z = randf_range(-600.0, 600.0)
	#var intensity: float = randf()
	#
	#if is_ball_in_range: ### SHOOT BALL
		#drag_direction.y = sqrt(direction.length()) * 3
		#ball.apply_hit_force(direction)
	#else: ## MOVE ENEMY
		#var intensity_multiplier: int = randi_range(15, 25)
		#direction.x = (ball.global_position.x - closest_enemy_from_ball.global_position.x) * intensity_multiplier
		#direction.z = (ball.global_position.z - closest_enemy_from_ball.global_position.z) * intensity_multiplier
		#closest_enemy_from_ball.apply_hit_force(direction)
	#is_my_turn = true

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

@onready var goal_scored_node: Control = $HUD/Control/Goal_Scored_Node

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
	
	await get_tree().create_timer(3.0).timeout.connect(reset_entities_position)
	#has_game_started = true
@onready var football_fans: Node2D = $HUD/Control/Goal_Scored_Node/Football_Fans

func play_cheer_effect() -> void:
		
	for football_fan in football_fans.get_children():
		var tween: Tween = create_tween()
		var start_pos: Vector2 = football_fan.position
		tween.tween_interval(randf_range(0.1, 0.5))
		for i in range(0, 5):
			tween.tween_property(football_fan, "scale", Vector2(1.2, 0.8), 0.1)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

			# 2. Odskoči: uži i viši, istovremeno ide gore
			tween.set_parallel(true)
			tween.tween_property(football_fan, "scale", Vector2(0.85, 1.2), 0.15)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tween.tween_property(football_fan, "position:y", start_pos.y - 60, 0.25)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

			# 3. Vrati se dole
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
	is_my_turn = true

func on_scored() -> void:
	my_score += 1
	my_score_label.text = str(my_score)
	is_my_turn = false
		
