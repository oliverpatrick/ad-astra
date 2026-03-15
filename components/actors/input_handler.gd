class_name InputHandler extends Node

var input_dir: Vector2 = Vector2.ZERO
var jump_pressed: bool = false
var menu_pressed: bool = false
var switch_camera: bool = false

func update() -> void:
	input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	jump_pressed = Input.is_action_just_pressed("jump")
	menu_pressed = Input.is_action_just_pressed("menu")
	switch_camera = Input.is_action_just_pressed("switch_camera")
