class_name MultiplayerPlayer extends RigidBody3D

signal player_selected(player: MultiplayerPlayer)
signal finished_move(player: MultiplayerPlayer)
signal continued_move(player: MultiplayerPlayer)

enum MoveState { IDLE, MOVING }

#enum MultiplayerPlayer {
	#HOST,
	#GUEST
#}

var player_id: int

var is_selected: bool = false

var is_moving: bool = false
var is_shooting: bool = false

var is_ball_in_range: bool = false
@onready var shooting_area_indicator: Sprite3D = $Shooting_Area_Indicator
@onready var top_part: MeshInstance3D = $Top_Part

var has_finished_move: bool = false
var went_over: bool = false

const SPEED_TO_START_MOVE: float = 0.5
const SPEED_TO_FINISH_MOVE: float = 0.2  
const SETTLE_TIME: float = 0.15          

var move_state: MoveState = MoveState.IDLE
var settle_timer: float = 0.0

var spawn_position: Vector3 = Vector3.ZERO

var is_owner: bool = false

#AUDIO
var can_play_sound: bool = false
@onready var swish_sound: AudioStreamPlayer = $Swish_Sound
@onready var player_collide_sound: AudioStreamPlayer = $Player_Collide_Sound

var scene: MultiplayerScene

func _ready() -> void:
	scene = get_tree().get_first_node_in_group("multiplayer_scene")
	if scene:
		scene.register_player(self)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not scene.is_my_turn: return
	var linear_velocity_length = state.linear_velocity.length()
	var speed: float = linear_velocity_length + state.angular_velocity.length() * 0.5
		
	match move_state:
		MoveState.IDLE:
			if speed > SPEED_TO_START_MOVE:
				move_state = MoveState.MOVING
				settle_timer = 0.0
				continued_move.emit(self)

		MoveState.MOVING:
			if speed < SPEED_TO_FINISH_MOVE:
				settle_timer += state.step
				if settle_timer >= SETTLE_TIME:
					move_state = MoveState.IDLE
					finished_move.emit(self)
			else:
				settle_timer = 0.0

			

func set_player_shooting():
	is_shooting = true
	is_moving = false

func set_player_not_shooting():
	is_shooting = false

func set_player_moving():
	is_moving = true
	is_shooting = false

func set_player_not_moving():
	is_moving = false

func on_action_done():
	is_moving = false
	is_shooting = false
	shooting_area_indicator.visible = false

func apply_hit_force(drag_direction: Vector3):
	drag_direction.x = clamp(drag_direction.x, -600.0, 600.0)
	drag_direction.z = clamp(drag_direction.z, -600.0, 600.0)
	swish_sound.pitch_scale = randf_range(1.5, 2.0)
	swish_sound.play()
	apply_central_impulse(drag_direction * 0.5)


func on_player_deselected():
	shooting_area_indicator.visible = false

func _on_selection_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		if is_owner:
			player_selected.emit(self)
		#else:
			#player_selected.emit(self)


func _on_shooting_area_body_entered(body: Node3D) -> void:
	if body is MultiplayerBall:
		is_ball_in_range = true


func _on_shooting_area_body_exited(body: Node3D) -> void:
	if body is MultiplayerBall:
		is_ball_in_range = false

func respawn_entity():
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = spawn_position

func play_collide_sound() -> void:
	if can_play_sound:
		player_collide_sound.pitch_scale = randf_range(0.9, 1.1)
		player_collide_sound.play()
		
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("multiplayer_player"):
		if get_instance_id() > body.get_instance_id():
			play_collide_sound()
	else:
		play_collide_sound()

func set_skin(skin_id: int, is_host: bool):
	var skin_texture: CompressedTexture2D = SkinsManager.get_skin_texture_from_id(skin_id)
	var material = top_part.get_surface_override_material(0) as StandardMaterial3D
	
	if not material:
		var active_mat = top_part.get_active_material(0) as StandardMaterial3D
		if active_mat:
			material = active_mat.duplicate() as StandardMaterial3D
			top_part.set_surface_override_material(0, material)
		else:
			material = StandardMaterial3D.new()
			top_part.set_surface_override_material(0, material)
	
	if material:
		material.albedo_texture = skin_texture
		if is_host:
			material.albedo_color = Color("2048ff")
		else:
			material.albedo_color = Color("ff0000")
