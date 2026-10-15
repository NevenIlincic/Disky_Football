class_name Ball extends RigidBody3D

signal finished_move(ball: Ball)
signal continued_move(ball: Ball)

enum MoveState { IDLE, MOVING }

const MIN_FORCE: float = 10.0
const MAX_FORCE: float = 40.0

const MAX_SPEED: float = 75.0

const SPEED_TO_START_MOVE: float = 3.0
const SPEED_TO_FINISH_MOVE: float = 2.0  # niži prag za kraj (histerezis)
const SETTLE_TIME: float = 0.15          # koliko dugo mora biti sporo

var move_state: MoveState = MoveState.IDLE
var settle_timer: float = 0.0

@onready var fire_effect: ShootEffect = $Fire_Effect
@onready var wave_effect: GPUParticles3D = $"../Wave_Effect"

var has_finished_move: bool = false
var went_over: bool = false

var spawn_position: Vector3 = Vector3.ZERO

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var linear_velocity_length = state.linear_velocity.length()
	var speed: float = linear_velocity_length + state.angular_velocity.length() * 0.5
	
	if linear_velocity_length > MAX_SPEED:
		state.linear_velocity = state.linear_velocity.normalized() * MAX_SPEED
	
	if linear_velocity_length > 10.0 and linear_velocity_length < 20.0:
		fire_effect.reduce_amount()
	if linear_velocity_length< 10.0 and fire_effect.emitting:
		fire_effect.stop_effects()
		
		
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
	wave_effect.global_position = global_position
	drag_direction.x = clamp(drag_direction.x, -600.0, 600.0)
	drag_direction.z = clamp(drag_direction.z, -600.0, 600.0)
	apply_central_impulse(drag_direction)
	fire_effect.emit_effects()
	wave_effect.emitting = true
	has_finished_move = false

func respawn_entity():
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_position = spawn_position
