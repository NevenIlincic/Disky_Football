class_name Enemy extends RigidBody3D

signal finished_move(enemy: Enemy)
signal continued_move(enemy: Enemy)

enum MoveState { IDLE, MOVING }

var is_ball_in_range: bool = false

var has_finished_move: bool = false
var went_over: bool = false

const SPEED_TO_START_MOVE: float = 0.5
const SPEED_TO_FINISH_MOVE: float = 0.2  
const SETTLE_TIME: float = 0.15          

var move_state: MoveState = MoveState.IDLE
var settle_timer: float = 0.0

var enemy_id: String

var spawn_position: Vector3 = Vector3.ZERO

func _ready() -> void:
	enemy_id = str(Time.get_ticks_usec(),"_", randi())

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
