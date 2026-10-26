class_name LevelScene extends Node3D

@onready var multiplayer_pause_menu: MultiplayerPauseMenu = $HUD/Control/MultiplayerPauseMenu
@onready var post_match_screen: PostMatchScreen = $HUD/Control/PostMatchScreen
@onready var indicator_line: Line2D = $HUD/Indicator_Line
@onready var power_bar: TextureProgressBar = $HUD/Control/Power_Bar

var drag_direction: Vector3

var start_position: Vector2
var end_position: Vector2

var is_dragging: bool = false
var is_action: bool = false

var selected_player: Object

const MAX_DRAG_LENGTH: float = 500.0
const MIN_DRAG_LENGTH: float = 35.0
const INDICATOR_LENGTH: float = 5.0

var ball: Ball

func _process(delta: float) -> void:
	if is_dragging:
		calculate_drag_direction()
		draw_indicator()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("drag"):
		if selected_player and (selected_player.is_moving or selected_player.is_shooting):
			is_dragging = true
			start_position = get_viewport().get_mouse_position()
			end_position = start_position
			drag_direction = Vector3.ZERO

	if Input.is_action_just_released("drag") and is_dragging:
		is_dragging = false
		calculate_drag_direction()
		do_action()
		
	if Input.is_action_pressed("pause_menu") and not post_match_screen.visible:
		multiplayer_pause_menu.visible = true
	if Input.is_action_just_released("pause_menu"):
		multiplayer_pause_menu.visible = false

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
	pass
