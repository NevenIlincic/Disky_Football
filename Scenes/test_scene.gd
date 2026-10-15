extends Node3D

#TIME
var time_passed: float = 0

var is_dragging: bool = false
var start_position: Vector2
var end_position: Vector2

var is_action: bool = false

#@onready var player: Player = $Player
@onready var ball: Ball = $Field/Ball


var selected_player: Player

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
var num_players: int

var players: Array[Player]

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("drag"):
		if selected_player and (selected_player.is_moving or selected_player.is_shooting):
			is_dragging = true
			start_position = get_viewport().get_mouse_position()
			shooting_indicator.visible = true
			
	if Input.is_action_just_released("drag"):
		is_dragging = false
		do_action()
		

func _ready() -> void:
	ball.finished_move.connect(_on_ball_finished_move)
	ball.continued_move.connect(_on_ball_continued_move)
	
	for player_obj in get_tree().get_nodes_in_group("player"):
		var player: Player = player_obj
		players.append(player)
		player.player_selected.connect(_on_player_selected)
		player.finished_move.connect(_on_player_finished_move)
		player.continued_move.connect(_on_player_continued_move)
		num_players += 1

func _on_player_continued_move(player: Player):
	_on_move_continued()	
func _on_ball_continued_move(ball: Ball):
	_on_move_continued()
func _on_move_continued():
	elements_in_action += 1
	if not is_action:
		is_action = true
func _reset_elements_in_action():
	elements_in_action = 0
	#ball.went_over = false
	#for player: Player in players:
		#player.went_over = false

func _on_ball_finished_move(ball: Ball):
	elements_in_action -= 1
	if elements_in_action <= 0 and is_action:
		is_action = false
		_reset_elements_in_action()

func _on_player_finished_move(player: Player):
	elements_in_action -= 1

	if elements_in_action <= 0 and is_action:
		is_action = false
		_reset_elements_in_action()

func _process(delta: float) -> void:
	if is_action:
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
	ball.has_finished_move = false
	for player: Player in players:
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
	
func _on_player_selected(player: Player):
	if is_action:
		return
	if selected_player:
		selected_player.on_player_deselected()
		if selected_player.player_id == player.player_id and not selected_player.is_moving and not selected_player.is_shooting:
			selected_player = null
			buttons.visible = false
			power_bar.visible = false
			return
			
	selected_player = player
	show_selected_player_elements(selected_player)


func show_selected_player_elements(player: Player):
	if selected_player.is_ball_in_range:
		kick_button.disabled = false
	else:
		kick_button.disabled = true
	buttons.visible = true
	power_bar.visible = true
	selected_player.shooting_area_indicator.visible = true

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
