class_name Enemy extends RigidBody3D

signal finished_move(enemy: Enemy)
signal continued_move(enemy: Enemy)

enum MoveState { IDLE, MOVING }

var is_ball_in_range: bool = false

var has_finished_move: bool = false
var went_over: bool = false

const SPEED_TO_START_MOVE: float = 0.5
const SPEED_TO_FINISH_MOVE: float = 0.2  
const SETTLE_TIME: float = 0.5         

var move_state: MoveState = MoveState.IDLE
var settle_timer: float = 0.0

var enemy_id: int

var spawn_position: Vector3 = Vector3.ZERO

#AUDIO
@onready var swish_sound: AudioStreamPlayer = $Swish_Sound
@onready var player_collide_sound: AudioStreamPlayer = $Player_Collide_Sound
var can_play_sound: bool = false


var scene: SinglePlayerScene
@onready var top_part: MeshInstance3D = $Top_Part

func _ready() -> void:
	scene = get_tree().get_first_node_in_group("singleplayer_scene")
	if scene:
		scene.register_enemy(self)
		

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
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

func apply_hit_force(drag_direction: Vector3):
	drag_direction.x = clamp(drag_direction.x, -600.0, 600.0)
	drag_direction.z = clamp(drag_direction.z, -600.0, 600.0)
	swish_sound.pitch_scale = randf_range(1.5, 2.0)
	swish_sound.play()
	apply_central_impulse(drag_direction * 0.5)	
	
func _on_shooting_area_body_entered(body: Node3D) -> void:
	if body is Ball:
		is_ball_in_range = true


func _on_shooting_area_body_exited(body: Node3D) -> void:
	if body is Ball:
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
	if body.is_in_group("player") or body.is_in_group("enemy"):
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
