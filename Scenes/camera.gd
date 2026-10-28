extends Camera3D

var is_dragging: bool = false
var speed: float = 20.0

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.0
@export var max_zoom: float = 2.0
const MOUSE_SENSITIVITY: float = 0.05

var current_zoom_value: float = 0.0
const ZOOM_DISTANCE: float = 1.0

const CAMERA_MIN_X: float = -50.0
const CAMERA_MAX_X: float = 50.0
const CAMERA_MIN_Z: float = -5.0
const CAMERA_MAX_Z: float = 25.0

var is_mobile_device: bool = false

var touch_points: Dictionary = {}   # index -> Vector2 (trenutna pozicija)
var last_pinch_distance: float = 0.0

const PINCH_SENSITIVITY: float = 0.01   # podesi po potrebi
const TOUCH_PAN_SENSITIVITY: float = 0.02

func _ready() -> void:
	is_mobile_device = WebSdk.SDK.check_is_on_mobile_device()

func _unhandled_input(event: InputEvent) -> void:
	if is_mobile_device:
		_handle_touch_input(event)
	else:
		_handle_desktop_input(event)


func _handle_desktop_input(event: InputEvent) -> void:
	if event.is_action_pressed("camera_drag"):
		is_dragging = true
	if event.is_action_released("camera_drag"):
		is_dragging = false

	if event is InputEventMouseMotion and is_dragging:
		_pan_camera(event.relative, MOUSE_SENSITIVITY)

	if event.is_action_pressed("zoom_in"):
		_zoom_in()
	if event.is_action_pressed("zoom_out"):
		_zoom_out()


func _handle_touch_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
		else:
			touch_points.erase(event.index)

		last_pinch_distance = 0.0
		if touch_points.size() == 2:
			var points: Array = touch_points.values()
			last_pinch_distance = (points[0] as Vector2).distance_to(points[1])

	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position

		if touch_points.size() == 1:
			_pan_camera(event.relative, TOUCH_PAN_SENSITIVITY)

		elif touch_points.size() == 2:
			var points: Array = touch_points.values()
			var current_distance: float = (points[0] as Vector2).distance_to(points[1])

			if last_pinch_distance > 0.0:
				var delta: float = current_distance - last_pinch_distance
				if absf(delta) > 1.0 / PINCH_SENSITIVITY * 0.05:
					if delta > 0.0:
						_zoom_in()
					else:
						_zoom_out()
					last_pinch_distance = current_distance
			else:
				last_pinch_distance = current_distance


func _pan_camera(relative: Vector2, sensitivity: float) -> void:
	var factor: float = sensitivity / (1.0 + current_zoom_value)

	global_position.x -= relative.x * factor
	global_position.x = clampf(global_position.x, CAMERA_MIN_X, CAMERA_MAX_X)

	global_position.z -= relative.y * factor
	global_position.z = clampf(global_position.z, CAMERA_MIN_Z, CAMERA_MAX_Z)

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
