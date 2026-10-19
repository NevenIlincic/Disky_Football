class_name MultiplayerScene extends Node3D

enum MatchState{
	PLAYING,
	WON_ON_TIME,
	WON_BY_GOALS,
	WON_BY_OPPONENT_DISCONNECTION,
	LOST_ON_TIME,
	LOST_BY_GOALS,
	DRAW
}
enum MatchFinishState {
	FINISHED_NORMAL,
	FINISHED_BY_DISCONNECTION
}

const MATCH_DURATION: float = 2700
const GOALS_TO_WIN: int = 1
var match_state: MatchState = MatchState.PLAYING
var match_finish_state: MatchFinishState = MatchFinishState.FINISHED_NORMAL

const PLAYER_SCENE = preload("uid://bop3seu5ydqe1")
const BALL_SCENE = preload("res://Scenes/Ball/MultiplayerBall.tscn")
@onready var fusion_spawner: FusionSpawner = $FusionSpawner
@onready var post_match_screen: PostMatchScreen = $HUD/Control/PostMatchScreen




var is_my_turn: bool = true:
	set(value):
		is_my_turn = value
		if value:
			turn_label.text = "YOUR TURN"
		else:
			turn_label.text = "OPPONENT's TURN"
@onready var turn_label: Label = $HUD/Control/Turn_Label

#TIME
var time_passed: float = 0

var is_dragging: bool = false
var start_position: Vector2
var end_position: Vector2

var is_action: bool = false
var is_initialy_host: bool = false

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
@onready var synchronizing_label: Label = $HUD/Control/Synchronizing_Label
@onready var host_team_name: Label = $HUD/Control/Scoreboard/Host_Team_Name
@onready var guest_team_name: Label = $HUD/Control/Scoreboard/Guest_Team_Name
@onready var host_name_label: Label = $HUD/Control/Scoreboard/Host_Name_Label
@onready var guest_name_label: Label = $HUD/Control/Scoreboard/Guest_Name_Label

@onready var my_goal: Goal = $Field/My_Goal
@onready var enemy_goal: Goal = $Field/Enemy_Goal

var is_initial_kick: bool = true

var ball: MultiplayerBall

#AUDIO
@onready var referee_whistle_sound: AudioStreamPlayer = $Referee_Whistle_Sound
@onready var goal_scored_sound: AudioStreamPlayer = $Goal_Scored_Sound

var loaded_peers := {}
var field_spawned := false

var snapshot_tick: int = 0
var target_positions: Dictionary = {}
var ball_target_pos: Vector3 = Vector3.ZERO
var ball_target_rot: Quaternion = Quaternion.IDENTITY
var has_snapshot: bool = false

var is_synchronization_done: bool = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if is_my_turn:
		if Input.is_action_just_pressed("drag"):
			if selected_player and (selected_player.is_moving or selected_player.is_shooting):
				is_dragging = true
				start_position = get_viewport().get_mouse_position()
				shooting_indicator.visible = true
				
		if Input.is_action_just_released("drag"):
			is_dragging = false
			do_action()


func reset_entities_position():
	match match_state:
		MatchState.PLAYING:
			for player: MultiplayerPlayer in multiplayer_players:
				player.respawn_entity()

			ball.respawn_entity()
			my_goal.reset_entity()
			enemy_goal.reset_entity()
			goal_scored_node.visible = false
			await get_tree().physics_frame
			
			referee_whistle_sound.play()
			Fusion.rpc(game_started)
			
		_:
			_on_match_finished()
			#if MatchFinishState.FINISHED_NORMAL:
				#FusionSdk.leave_room()


func _on_match_finished():
	FusionSdk.leave_room()
	goal_scored_node.visible = false
	post_match_screen.visible = true
	post_match_screen.do_after_match()
	
	

func handle_won_by_opponents_disconnection():
	match_state = MatchState.WON_BY_OPPONENT_DISCONNECTION
	
func _on_player_left(player_id: int, is_inactive: bool):
	await get_tree().create_timer(1.0).timeout
	if match_state == MatchState.PLAYING:
		handle_won_by_opponents_disconnection()
	_on_match_finished()

func spawn_players():
	for host_spawn_point in get_tree().get_nodes_in_group("host_spawn_point"):
		host_spawn_points.append(host_spawn_point)
	for guest_spawn_point in get_tree().get_nodes_in_group("guest_spawn_point"):
		guest_spawn_points.append(guest_spawn_point)
		
	for i in range(0, 12):
		var player: MultiplayerPlayer = PLAYER_SCENE.instantiate()
		add_child(player)
	
var next_player_id: int = 0

func register_player(player: MultiplayerPlayer) -> void:
	player.player_id = next_player_id
	
	var player_spawn_position: Vector3
	if next_player_id <= 5:
		if Fusion.is_master_client():
			player.is_owner = true
		player_spawn_position = host_spawn_points[next_player_id].global_position
	else:
		if not Fusion.is_master_client():
			player.is_owner = true
		player_spawn_position = guest_spawn_points[next_player_id - 6].global_position
	
	player.global_position = player_spawn_position
	player.spawn_position = player_spawn_position
		
	player.player_selected.connect(_on_player_selected)
	player.finished_move.connect(_on_player_finished_move)
	player.continued_move.connect(_on_player_continued_move)

	multiplayer_players.append(player)
	num_players += 1
	next_player_id += 1
	
func register_ball(b: MultiplayerBall) -> void:
	ball = b
	ball.finished_move.connect(_on_ball_finished_move)
	ball.continued_move.connect(_on_ball_continued_move)
		

func spawn_ball():
	ball = BALL_SCENE.instantiate()
	add_child(ball)
	ball.global_position = ball_spawn_position.global_position
	ball.spawn_position = ball.global_position

func _enter_tree() -> void:
	Fusion.register_broadcast_receiver(self)

func _exit_tree() -> void:
	Fusion.unregister_broadcast_receiver(self)
	#if Fusion.room_left.is_connected(_on_match_finished):
		#Fusion.room_left.disconnect(_on_match_finished)
	if Fusion.player_left.is_connected(_on_player_left):
		Fusion.player_left.disconnect(_on_player_left)
	if my_goal.goal_scored.is_connected(_on_goal_scored):
		my_goal.goal_scored.disconnect(_on_goal_scored)
	if enemy_goal.goal_scored.is_connected(_on_goal_scored):
		enemy_goal.goal_scored.disconnect(_on_goal_scored)
		
func set_team_name_labels() -> void:
	if Fusion.is_master_client():
		host_team_name.text = FusionSdk.my_team_name
		guest_team_name.text = FusionSdk.get_opponents_team_name()
		
		host_name_label.text = FusionSdk.my_name
		guest_name_label.text = FusionSdk.get_opponents_name()
	else:
		host_team_name.text = FusionSdk.get_opponents_team_name()
		guest_team_name.text = FusionSdk.my_team_name
		
		host_name_label.text = FusionSdk.get_opponents_name()
		guest_name_label.text = FusionSdk.my_name
		
func _ready() -> void:
	#Fusion.room_left.connect(_on_match_finished)
	Fusion.player_left.connect(_on_player_left)
	is_my_turn = Fusion.is_master_client()
	is_initialy_host = Fusion.is_master_client()
	set_team_name_labels()
	
	my_goal.goal_scored.connect(_on_goal_scored)
	enemy_goal.goal_scored.connect(_on_goal_scored)
	
	var my_id = FusionSdk.id
	spawn_field()
	#Fusion.rpc(game_started)
	#has_game_started = true
	referee_whistle_sound.play()
	if Fusion.is_master_client():
		peer_scene_ready(my_id)
	else:
		Fusion.rpc_to(Fusion.TARGET_MASTER, peer_scene_ready, my_id)
	
@rpc("any_peer", "call_local")
func peer_scene_ready(pid: String) -> void:
	if not Fusion.is_master_client() or field_spawned:
		return
	loaded_peers[pid] = true
	if loaded_peers.size() == 2:
		Fusion.rpc(game_started)
		#field_spawned = true
		#spawn_field()
		
func spawn_field():
	spawn_ball()
	spawn_players()


func _on_player_continued_move(player: MultiplayerPlayer):
	if not is_my_turn: return
	_on_move_continued()	
func _on_ball_continued_move(ball: MultiplayerBall):
	if not is_my_turn: return
	_on_move_continued()
func _on_move_continued():
	elements_in_action += 1
	if not is_action:
		is_action = true
		
func _on_move_finished():
	elements_in_action -= 1

	if elements_in_action <= 0 and is_action:
		synchronizing_label.visible = true
		Fusion.rpc(action_ended)
		var s := build_snapshot()
		Fusion.rpc(handle_end_turn_synhronization, s, time_passed)
		_reset_elements_in_action()
		#if not is_my_turn:
			#await get_tree().create_timer(2.0).timeout.connect(handle_enemy_turn)
	
func _reset_elements_in_action():
	elements_in_action = 0


func _on_ball_finished_move(ball: MultiplayerBall):
	if not is_my_turn: return
	_on_move_finished()
	#elements_in_action -= 1
	#if elements_in_action <= 0 and is_action:
		#is_action = false
		#_reset_elements_in_action()

func _on_player_finished_move(player: MultiplayerPlayer):
	if not is_my_turn: return
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
			
			#Fusion.rpc(move_player, drag_direction, selected_player.player_id)
			on_action_done()

		elif selected_player.is_shooting:
			#Fusion.rpc(shoot_ball, drag_direction, drag_distance)
			drag_direction.y =  roundi(sqrt(drag_distance.length()) * 3)
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
	Fusion.rpc(action_started)
	#is_action = true
	selected_player = null
	#is_my_turn = false
	
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
	await get_tree().create_timer(0.2).timeout
	Fusion.rpc(action_ended)
	#is_action = false
	Fusion.rpc(game_paused)
	#has_game_started = false
	Fusion.rpc(handle_goal_scored, goal_owner)
	#goal_scored_node.visible = true
	#play_goal_effect()
	#play_cheer_effect()

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
	if enemy_score < GOALS_TO_WIN:
		if is_initialy_host:
			is_my_turn = true
		else:
			is_my_turn = false
	else:
		if is_initialy_host:
			match_state = MatchState.LOST_BY_GOALS
		else:
			match_state = MatchState.WON_BY_GOALS

func handle_match_lost():
	print("POBEDIO!")

func on_scored() -> void:
	my_score += 1
	my_score_label.text = str(my_score)
	if my_score < GOALS_TO_WIN:
		if is_initialy_host:
			is_my_turn = false
		else:
			is_my_turn = true
	else:
		if is_initialy_host:
			match_state = MatchState.WON_BY_GOALS
		else:
			match_state = MatchState.LOST_BY_GOALS
		
func get_selected_player(selected_player_id: int) -> MultiplayerPlayer:
	var found_player: MultiplayerPlayer
	for player: MultiplayerPlayer in multiplayer_players:
		if player.player_id == selected_player_id:
			found_player = player
			break
	return found_player

func _physics_process(delta: float) -> void:
	if not is_action or not ball and match_state == MatchState.PLAYING:
		synchronizing_label.visible = false
		return
	synchronizing_label.visible = true
	if is_my_turn:
		snapshot_tick += 1
		if snapshot_tick % 3 == 0 and is_action:
			var s := build_snapshot()
			Fusion.rpc(receive_snapshot, s.ids, s.positions, s.ball_pos, s.ball_rot, false)
	else:
		apply_targets()
		
	if time_passed < MATCH_DURATION:
		if Fusion.is_master_client():
			print(time_passed)
	
	if time_passed > MATCH_DURATION and match_state == MatchState.PLAYING:
		for player: MultiplayerPlayer in multiplayer_players:
			freeze_entities(player)
		freeze_entities(ball)
		Fusion.rpc(handle_match_finished_on_time)
func build_snapshot() -> Dictionary:
	var ids: Array = []
	var positions: Array = []
	for p: MultiplayerPlayer in multiplayer_players:
		ids.append(p.player_id)
		positions.append(p.global_position)
	return {
		"ids": ids,
		"positions": positions,
		"ball_pos": ball.global_position,
		"ball_rot": ball.global_basis.get_rotation_quaternion(),
	}

@rpc("any_peer", "call_remote")
func receive_snapshot(ids: Array, positions: Array, ball_pos: Vector3, ball_rot: Quaternion, is_synchronizing: bool) -> void:
	if is_my_turn:
		return
	for i in ids.size():
		target_positions[ids[i]] = positions[i]
	ball_target_pos = ball_pos
	ball_target_rot = ball_rot
	has_snapshot = true
	
	#if is_synchronizing:
		#apply_targets()

func apply_targets() -> void:
	if not has_snapshot or not ball:
		return
	for id in target_positions:
		var p := get_selected_player(id)
		if p:
			p.global_position = p.global_position.lerp(target_positions[id], 0.3)
	ball.global_position = ball.global_position.lerp(ball_target_pos, 0.3)
	var cur := ball.global_basis.get_rotation_quaternion()
	ball.global_basis = Basis(cur.slerp(ball_target_rot, 0.3))

#@rpc("any_peer", "call_remote")
func apply_end_turn_targets_synchronization(snapshot: Dictionary) -> void:
	var ids: Array = snapshot["ids"]
	var positions: Array = snapshot["positions"]
	var ball_position = snapshot["ball_pos"]
	for i in ids.size():
		target_positions[ids[i]] = positions[i]
	for id in ids:
		var p := get_selected_player(id)
		if p:
			p.global_position = target_positions[id]
	ball.global_position = ball_target_pos
	#ball.global_basis = ball_target_rot
	target_positions.clear()
	
	on_synchronization_done()

func on_synchronization_done():
	Fusion.rpc(turn_changed)
	Fusion.rpc(reset_target_positions)

func set_body_authority(body: RigidBody3D) -> void:
	if is_my_turn:
		body.freeze = false
	else:
		body.linear_velocity = Vector3.ZERO
		body.angular_velocity = Vector3.ZERO
		body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		body.freeze = true

func freeze_entities(body: RigidBody3D) -> void:
	body.freeze = true

#RPC
@rpc("any_peer", "call_remote")
func action_started() -> void:
	is_action = true

@rpc("any_peer", "call_local")
func action_ended() -> void:
	is_action = false

@rpc("any_peer", "call_local")
func turn_changed() -> void:
	is_my_turn = !is_my_turn
	synchronizing_label.visible = false
	
@rpc("any_peer", "call_local")
func game_started() -> void:
	has_game_started = true

@rpc("any_peer", "call_local")
func game_paused() -> void:
	has_game_started = false

@rpc("any_peer", "call_local")
func reset_target_positions():
	target_positions.clear()

@rpc("any_peer", "call_remote")
func handle_end_turn_synhronization(snapshot: Dictionary, time: float):
	time_passed = time
	var minutes: int = int(time_passed) / 60
	var seconds: int = int(time_passed) % 60
	
	time_label.text = "%02d:%02d" % [minutes, seconds]
	
	apply_end_turn_targets_synchronization(snapshot)
	#var s := build_snapshot()
	#Fusion.rpc(receive_snapshot, s.ids, s.positions, s.ball_pos, s.ball_rot)

@rpc("any_peer", "call_local")
func handle_goal_scored(goal_owner: Goal.GoalOwner):
	goal_scored_node.visible = true
	play_goal_effect()
	play_cheer_effect()
	await get_tree().create_timer(3.0).timeout
	if goal_owner == Goal.GoalOwner.ME:
		on_enemy_scored()
	else:
		on_scored()
	reset_entities_position()

@rpc("any_peer", "call_local")
func handle_match_finished_on_time():
	is_action = false
	if my_score == enemy_score:
		match_state = MatchState.DRAW
	elif is_initialy_host:
		if my_score > enemy_score:
			match_state = MatchState.WON_ON_TIME
		else:
			match_state = MatchState.LOST_ON_TIME
	else:
		if enemy_score > my_score:
			match_state = MatchState.WON_ON_TIME
		else:
			match_state = MatchState.LOST_ON_TIME
	_on_match_finished()
