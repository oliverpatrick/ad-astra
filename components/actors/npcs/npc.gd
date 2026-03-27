extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
## Whether this character can push other CharacterBody3D nodes.
@export var push_characters := true
## How strongly characters get pushed (0-1 blends their velocity).
@export var character_push_strength := 0.8
## How quickly push velocity decays (higher = stops faster).
@export var push_friction := 20

## External push velocity, set by other characters. Decays over time.
var push_velocity := Vector3.ZERO


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Apply and decay push velocity from external forces.
	velocity += push_velocity
	push_velocity = push_velocity.move_toward(Vector3.ZERO, push_friction * delta)

	var intended_velocity := velocity

	move_and_slide()

	# Push other CharacterBody3D nodes if we have more velocity.
	if push_characters:
		for i in get_slide_collision_count():
			var collision := get_slide_collision(i)
			var collider := collision.get_collider()
			if collider is CharacterBody3D:
				var other := collider as CharacterBody3D
				var my_speed := intended_velocity.length()
				var other_speed := other.velocity.length()
				if my_speed >= other_speed:
					var push_dir := -collision.get_normal()
					push_dir.y = 0.0
					push_dir = push_dir.normalized()
					var push_amount := maxf(my_speed - other_speed, 1.0) * character_push_strength
					other.velocity += push_dir * push_amount
