extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
# Virtual mass of the character for push calculations
@export var character_mass := 100.0
# Tune this to make pushes feel right
@export var push_force_multiplier := 1.0
## Whether this character can push other CharacterBody3D nodes.
@export var push_characters := true
## How strongly characters get pushed (0-1 blends their velocity).
@export var character_push_strength := 0.1

@onready var camera_root: FPSCamera = %CameraRoot

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Camera-relative movement.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var forward := camera_root.get_camera_forward_xz()
	var right := camera_root.get_camera_right_xz()
	var direction := (forward * -input_dir.y + right * input_dir.x).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	var intended_velocity := velocity

	move_and_slide()
	
	# Push any RigidBody3D we collided with.
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider is RigidBody3D:
			var body := collider as RigidBody3D
			var push_dir := -collision.get_normal()
			push_dir.y = 0.0
			push_dir = push_dir.normalized()
			# Use intended velocity so pushing works even when already touching.
			var push_speed := maxf(intended_velocity.length(), 0.5)
			var force := push_dir * character_mass * push_force_multiplier * push_speed * delta
			body.apply_impulse(force, collision.get_position() - body.global_position)
		elif collider is CharacterBody3D and push_characters:
			var other := collider as CharacterBody3D
			var my_speed := intended_velocity.length()
			var other_speed := other.velocity.length()
			# Only the faster body applies the push to avoid double-pushing.
			if my_speed >= other_speed:
				var push_dir := -collision.get_normal()
				push_dir.y = 0.0
				push_dir = push_dir.normalized()
				var push_amount := maxf(my_speed - other_speed, 1.0) * character_push_strength
				# Use push_velocity if available so the push persists across frames.
				if "push_velocity" in other:
					other.push_velocity += push_dir * push_amount
				else:
					other.velocity += push_dir * push_amount
