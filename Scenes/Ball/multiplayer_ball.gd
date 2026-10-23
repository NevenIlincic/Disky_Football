class_name MultiplayerBall extends RigidBody3D

signal finished_move(ball: MultiplayerBall)
signal continued_move(ball: MultiplayerBall)
signal fire_effect_started(ball_effect_id: int)
signal fire_effect_amount_reduced(ball_effect_id: int)
signal fire_effect_stopped(ball_effect_id: int)


enum MoveState { IDLE, MOVING }

const MIN_FORCE: float = 10.0
const MAX_FORCE: float = 40.0

const MAX_SPEED: float = 75.0

const SPEED_TO_START_MOVE: float = 3.0
const SPEED_TO_FINISH_MOVE: float = 2.0  # niži prag za kraj (histerezis)
const SETTLE_TIME: float = 0.15          # koliko dugo mora biti sporo

var move_state: MoveState = MoveState.IDLE
var settle_timer: float = 0.0
@onready var kick_sound: AudioStreamPlayer = $Kick_Sound
#@onready var fire_effect: ShootEffect = $Fire_Effect
@onready var fire_effect: ShootEffect
var wave_effect: GPUParticles3D

var has_finished_move: bool = false
var went_over: bool = false

var is_full_fire_effect_active: bool = false
var is_reduced_fire_effect_active: bool = false
var is_fire_effect_stopped_active: bool = false

var spawn_position: Vector3 = Vector3.ZERO
var scene: MultiplayerScene
func _ready() -> void:
	wave_effect = get_tree().get_first_node_in_group("wave_effect")
	scene = get_tree().get_first_node_in_group("multiplayer_scene")
	if scene:
		scene.register_ball(self) 

func set_ball_effect(id: int) -> void:
	if fire_effect:
		fire_effect.queue_free()
	fire_effect = BallEffects.get_ball_effect_from_id(id)
	add_child(fire_effect)
	fire_effect.scale = Vector3(2.0, 2.0, 2.0)


var is_really_moving: bool = false
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	check_should_play_hit_sound(state)
	if not scene.is_my_turn: return

	var linear_velocity_length = state.linear_velocity.length()
	var speed: float = linear_velocity_length + state.angular_velocity.length() * 0.5
	
	if linear_velocity_length > MAX_SPEED:
		state.linear_velocity = state.linear_velocity.normalized() * MAX_SPEED
	
	if linear_velocity_length > 10.0 and linear_velocity_length < 20.0:
		if fire_effect and fire_effect.emitting and not is_reduced_fire_effect_active:
			is_reduced_fire_effect_active = true
			is_full_fire_effect_active = false
			is_fire_effect_stopped_active = false
			fire_effect.reduce_amount()
			fire_effect_amount_reduced.emit(BallEffects.selected_effect)
	
	if linear_velocity_length < 10.0:
		if fire_effect and fire_effect.emitting and not is_fire_effect_stopped_active:
			is_full_fire_effect_active = false
			is_reduced_fire_effect_active = false
			is_fire_effect_stopped_active = true
			
			fire_effect.stop_effects()
			fire_effect_stopped.emit(BallEffects.selected_effect)
		
		
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
					state.linear_velocity = Vector3.ZERO
					state.angular_velocity = Vector3.ZERO
					finished_move.emit(self)
			else:
				settle_timer = 0.0
var last_velocity: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	last_velocity = linear_velocity

func apply_hit_force(drag_direction: Vector3):
	wave_effect.global_position = global_position
	drag_direction.x = clamp(drag_direction.x, -600.0, 600.0)
	drag_direction.z = clamp(drag_direction.z, -600.0, 600.0)
	apply_central_impulse(drag_direction)
	set_ball_effect(BallEffects.selected_effect)
	fire_effect.emit_effects()
	wave_effect.emitting = true
	has_finished_move = false
	kick_sound.pitch_scale = randf_range(0.7, 1.0)
	kick_sound.play()
	if not is_full_fire_effect_active:
		is_full_fire_effect_active = true
		is_reduced_fire_effect_active = false
		is_fire_effect_stopped_active = false
		fire_effect_started.emit(BallEffects.selected_effect)

func respawn_entity():
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = spawn_position



func _on_body_entered(body: Node) -> void:
	var impact: float = last_velocity.length()
	if impact < 5.0:
		return
	kick_sound.volume_db = linear_to_db(clampf(impact / 15.0, 0.05, 1.0))
	kick_sound.pitch_scale = randf_range(0.9, 1.1)
	kick_sound.play()

const MIN_IMPACT_SPEED: float = 10.0  # minimalna brzina "udara" u normalu
const COOLDOWN: float = 0.3 
var _cooldown_left: float = 0.0

func check_should_play_hit_sound(state: PhysicsDirectBodyState3D) -> void:
	_cooldown_left -= state.step

	if _cooldown_left > 0.0:
		return

	for i in state.get_contact_count():
		var normal: Vector3 = state.get_contact_local_normal(i)
		var velocity_at_contact: Vector3 = state.get_contact_local_velocity_at_position(i) \
			- state.get_contact_collider_velocity_at_position(i)
		
		
		var normal_speed: float = absf(velocity_at_contact.dot(normal))
		if normal_speed > MIN_IMPACT_SPEED:
			kick_sound.volume_db = linear_to_db(clampf(normal_speed / 15.0, 0.05, 1.0))
			kick_sound.pitch_scale = randf_range(0.9, 1.1)
			kick_sound.play()
			_cooldown_left = COOLDOWN
			break
