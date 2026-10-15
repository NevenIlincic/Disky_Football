class_name Player extends RigidBody3D

signal player_selected(player: Player)
signal finished_move(player: Player)
signal continued_move(player: Player)

enum MoveState { IDLE, MOVING }

var player_id: String

var is_selected: bool = false

var is_moving: bool = false
var is_shooting: bool = false

var is_ball_in_range: bool = false
@onready var shooting_area_indicator: Sprite3D = $Shooting_Area_Indicator

var has_finished_move: bool = false
var went_over: bool = false

const SPEED_TO_START_MOVE: float = 0.5  # prag za početak
const SPEED_TO_FINISH_MOVE: float = 0.2  # niži prag za kraj (histerezis)
const SETTLE_TIME: float = 0.15          # koliko dugo mora biti sporo

var move_state: MoveState = MoveState.IDLE
var settle_timer: float = 0.0

func _ready() -> void:
	player_id = str(Time.get_ticks_usec(),"_", randi())

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
	apply_central_impulse(drag_direction * 0.5)


func on_player_deselected():
	shooting_area_indicator.visible = false

func _on_selection_area_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		player_selected.emit(self)


func _on_shooting_area_body_entered(body: Node3D) -> void:
	if body is Ball:
		is_ball_in_range = true


func _on_shooting_area_body_exited(body: Node3D) -> void:
	if body is Ball:
		is_ball_in_range = false
