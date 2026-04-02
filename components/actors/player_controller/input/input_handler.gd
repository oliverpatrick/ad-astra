class_name InputHandler 
extends Node

@onready var _pivot_y: Node3D = $"../CameraMount/PivotY"

func handle_inputs() -> InputPackage:
	var new_input = InputPackage.new()
	
	if Input.is_action_just_pressed("jump"):
		new_input.actions.append("jump")
		
	if Input.is_action_just_pressed("crouch"):
		new_input.actions.append("crouch")
		
	new_input.camera_basis = _pivot_y.global_transform.basis
	new_input.input_direction = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if new_input.input_direction != Vector2.ZERO:
		new_input.actions.append("run")
		
	if new_input.actions.is_empty():
		new_input.actions.append("idle")
	
	return new_input
