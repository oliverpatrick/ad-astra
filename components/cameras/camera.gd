class_name FPSCamera extends Node3D
## First-person camera that rotates with mouse input.
##
## Attach to a [Node3D] at eye height on the character. Add a [Camera3D] child.
## Yaw rotates the **parent body** so movement stays aligned with the view.
## Pitch rotates this node locally so the camera looks up/down.

# ── Tuning ───────────────────────────────────────────────────────────────────

## Mouse sensitivity in radians per pixel.
@export var mouse_sensitivity: float = 0.002
## Minimum pitch angle (degrees). Negative = look up.
@export var pitch_min: float = -89.0
## Maximum pitch angle (degrees). Positive = look down.
@export var pitch_max: float = 89.0

# ── State ────────────────────────────────────────────────────────────────────

var _yaw: float = 0.0
var _pitch: float = 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_yaw   -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch  = clampf(_pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))

		# Yaw rotates the character body so movement direction matches the view.
		get_parent().rotation.y = _yaw
		# Pitch rotates only this camera root.
		rotation.x = _pitch

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# ── Helpers for camera-relative movement ─────────────────────────────────────

## Horizontal forward direction the camera faces (ignoring pitch).
func get_camera_forward_xz() -> Vector3:
	return (-get_parent().global_basis.z * Vector3(1, 0, 1)).normalized()


## Horizontal right direction the camera faces.
func get_camera_right_xz() -> Vector3:
	return (get_parent().global_basis.x * Vector3(1, 0, 1)).normalized()
