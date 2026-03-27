class_name PlayerCharacter 
extends CharacterBody3D

@export_category("Movement")
@export var base_speed = 5
@export var sprint_multipler = 1.3

@export_category("Player Resources")

@onready var input_handler: InputHandler = $InputHandler
@onready var humanoid: Humanoid = $Humanoid


func _physics_process(delta: float) -> void:
	var input = input_handler.handle_inputs()
	humanoid.update(	input, delta)
	if Input.is_action_just_pressed("menu"):
		get_tree().quit()

	
