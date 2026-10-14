extends Camera3D

var is_dragging: bool = false
var speed: float = 20.0

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.0
@export var max_zoom: float = 2.0
const MOUSE_SENSITIVITY: float = 0.05

var current_zoom_value: float = 0.0
const ZOOM_DISTANCE: float = 1.0

func _unhandled_input(event: InputEvent) -> void:
	
	if Input.is_action_pressed("camera_drag"):
		is_dragging = true
	if Input.is_action_just_released("camera_drag"):
		is_dragging = false
	
	if event is InputEventMouseMotion and is_dragging:
		global_position.x -= event.relative.x * MOUSE_SENSITIVITY / (1 + current_zoom_value)
		global_position.z -= event.relative.y * MOUSE_SENSITIVITY / (1 + current_zoom_value)

	if Input.is_action_just_pressed("zoom_in"):
		_zoom_in()
		
	if Input.is_action_just_pressed("zoom_out"):
		_zoom_out()

func _zoom_in():
	current_zoom_value += 0.1
	current_zoom_value = clamp(current_zoom_value, min_zoom, max_zoom)
	if current_zoom_value >= max_zoom:
		return
	var forward_vector = -global_transform.basis.z
	global_position += ZOOM_DISTANCE * forward_vector
	
func _zoom_out():
	current_zoom_value -= 0.1
	current_zoom_value = clamp(current_zoom_value, min_zoom, max_zoom)
	if current_zoom_value <= min_zoom:
		return
	var forward_vector = -global_transform.basis.z
	global_position -= ZOOM_DISTANCE * forward_vector
