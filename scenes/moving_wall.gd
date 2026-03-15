extends AnimatableBody3D

@export var distance: float = 5.0
@export var speed: float = 2.0

var _start_pos: Vector3
var _time: float = 0.0


func _ready() -> void:
	_start_pos = global_position


func _physics_process(delta: float) -> void:
	_time += delta
	var offset := sin(_time * speed * TAU / (distance * 2.0)) * distance
	global_position = _start_pos + Vector3(0, 0, offset)
