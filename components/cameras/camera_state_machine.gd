extends Node

@export var mouse_sensitivity: float = 0.002
@export var pitch_min: float = -89.0
@export var pitch_max: float = 89.0

@onready var pivot_y: Node3D = $"../PivotY"
@onready var pivot_x: Node3D = $"../PivotY/PivotX"
@onready var third_person: Camera3D = $"../PivotY/PivotX/SpringArm3D/ThirdPersonCamera"
@onready var first_person: Camera3D = $"../PivotY/PivotX/FirstPersonCamera"

var _yaw: float = 0.0
var _pitch: float = 0.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	third_person.current = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clampf(_pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
		pivot_y.rotation.y = _yaw
		pivot_x.rotation.x = _pitch

	if event.is_action_pressed("switch_camera"):
		switch_camera()

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func switch_camera() -> void:
	if third_person.current:
		third_person.current = false
		first_person.current = true
	else:
		first_person.current = false
		third_person.current = true
