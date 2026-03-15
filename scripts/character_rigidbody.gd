class_name RigidCharacterBody extends RigidBody3D
## A RigidBody3D that replicates the CharacterBody3D [method move_and_slide] API.
##
## Enables velocity-based movement with floor/wall/ceiling detection and sliding
## while keeping the node as a [RigidBody3D] for physics interactions.
##
## Usage:[br]
##   1. Set [member velocity] each frame (apply gravity, input, etc.).[br]
##   2. Call [method move_and_slide] from [method Node._physics_process].[br]
##   3. Query [method is_on_floor], [method is_on_wall], [method is_on_ceiling].


# ── Enums ────────────────────────────────────────────────────────────────────

enum MotionMode {
	## Walls, ceiling and floor are relevant. Slopes cause acceleration/slowdown.
	MOTION_MODE_GROUNDED = 0,
	## No notion of floor or ceiling. All collisions reported as walls. Constant speed.
	MOTION_MODE_FLOATING = 1,
}

enum PlatformOnLeave {
	## Add the last platform velocity when leaving.
	PLATFORM_ON_LEAVE_ADD_VELOCITY = 0,
	## Add the last platform velocity but ignore downward motion.
	PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY = 1,
	## Do nothing when leaving a platform.
	PLATFORM_ON_LEAVE_DO_NOTHING = 2,
}


# ── Exported Properties ─────────────────────────────────────────────────────

## Current velocity vector (meters per second). Set this before calling
## [method move_and_slide]. It will be modified if a slide collision occurs.
@export var velocity: Vector3 = Vector3.ZERO

@export_group("Floor")
## If [code]true[/code], the body will not slide on slopes when standing still.
@export var floor_stop_on_slope: bool = true
## If [code]true[/code], the body moves at constant speed on slopes.
@export var floor_constant_speed: bool = false
## If [code]true[/code], the body can only move on the floor (prevents walking on walls).
@export var floor_block_on_wall: bool = true
## Maximum angle (radians) where a slope is still considered a floor. Default 45°.
@export var floor_max_angle: float = deg_to_rad(45.0)
## Snap distance to keep the body attached to slopes.
@export var floor_snap_length: float = 0.1

@export_group("Wall")
## Minimum slide angle (radians) when encountering a wall. Default 15°.
@export var wall_min_slide_angle: float = deg_to_rad(15.0)

@export_group("Ceiling")
## If [code]true[/code], the body slides against ceilings instead of stopping.
@export var slide_on_ceiling: bool = true

@export_group("General")
## Vector pointing upwards, used to classify floor/wall/ceiling.
@export var up_direction: Vector3 = Vector3.UP
## Whether the body uses grounded or floating motion.
@export var motion_mode: MotionMode = MotionMode.MOTION_MODE_GROUNDED
## Maximum number of slides per [method move_and_slide] call.
@export var max_slides: int = 6
## Extra collision recovery margin.
@export var safe_margin: float = 0.001

@export_group("Platform")
## Collision layers used to detect floor platforms.
@export var platform_floor_layers: int = 0xFFFFFFFF
## Collision layers used to detect wall platforms.
@export var platform_wall_layers: int = 0
## Behavior when leaving a moving platform.
@export var platform_on_leave: PlatformOnLeave = PlatformOnLeave.PLATFORM_ON_LEAVE_ADD_VELOCITY


# ── Internal State ───────────────────────────────────────────────────────────

var _on_floor: bool = false
var _on_ceiling: bool = false
var _on_wall: bool = false
var _floor_normal: Vector3 = Vector3.ZERO
var _wall_normal: Vector3 = Vector3.ZERO
var _last_motion: Vector3 = Vector3.ZERO
var _position_delta: Vector3 = Vector3.ZERO
var _real_velocity: Vector3 = Vector3.ZERO
var _platform_velocity: Vector3 = Vector3.ZERO
var _platform_angular_velocity: Vector3 = Vector3.ZERO
var _prev_platform_velocity: Vector3 = Vector3.ZERO
var _platform_rid: RID = RID()
var _slide_collisions: Array[KinematicCollision3D] = []


# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	# Disable default rigid-body integration so move_and_slide() has full control.
	custom_integrator = true


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	# Sync the physics-engine velocity so other rigid bodies react correctly
	# when they collide with us.  Angular velocity is zeroed because rotation
	# is not part of the CharacterBody3D model.
	state.linear_velocity = velocity
	state.angular_velocity = Vector3.ZERO


# ── Core Movement ────────────────────────────────────────────────────────────

## Moves the body based on [member velocity]. Handles sliding, floor/wall/ceiling
## detection, slope behavior, and floor snapping. Call once per physics frame.
## Returns [code]true[/code] if a collision occurred.
func move_and_slide() -> bool:
	var delta := get_physics_process_delta_time()
	var was_on_floor := _on_floor
	var prev_platform_vel := _prev_platform_velocity

	# Reset per-frame state
	_on_floor = false
	_on_ceiling = false
	_on_wall = false
	_floor_normal = Vector3.ZERO
	_wall_normal = Vector3.ZERO
	_position_delta = Vector3.ZERO
	_real_velocity = Vector3.ZERO
	_platform_velocity = Vector3.ZERO
	_platform_angular_velocity = Vector3.ZERO
	_platform_rid = RID()
	_slide_collisions.clear()

	# ── Apply platform velocity ─────────────────────────────────────────
	# If we were on a moving platform last frame, carry its velocity so the
	# character moves with the platform.
	var motion := velocity * delta
	if was_on_floor and prev_platform_vel.length() > 0.001:
		motion += prev_platform_vel * delta

	var initial_velocity := velocity

	for i in max_slides:
		var collision := move_and_collide(motion, false, safe_margin)

		if collision == null:
			# No collision — full remaining motion applied.
			_position_delta += motion
			_last_motion = motion
			break

		_slide_collisions.append(collision)
		_last_motion = collision.get_travel()
		_position_delta += collision.get_travel()

		var normal := collision.get_normal()

		# ── Classify surface ─────────────────────────────────────────────
		if motion_mode == MotionMode.MOTION_MODE_GROUNDED:
			var angle_to_up := normal.angle_to(up_direction)
			if angle_to_up <= floor_max_angle:
				_on_floor = true
				_floor_normal = normal
			elif angle_to_up >= PI - floor_max_angle:
				_on_ceiling = true
			else:
				_on_wall = true
				_wall_normal = normal
		else:
			# Floating mode — everything is a wall.
			_on_wall = true
			_wall_normal = normal

		# ── Compute slide motion ─────────────────────────────────────────
		var remainder := collision.get_remainder()

		# Stop on slope when velocity is negligible.
		if _on_floor and floor_stop_on_slope:
			if initial_velocity.slide(normal).length() < 0.01:
				motion = Vector3.ZERO
				velocity = Vector3.ZERO
				break

		if _on_floor and floor_constant_speed:
			# Maintain speed on slopes.
			var slide_motion := remainder.slide(normal)
			if slide_motion.length() > 0.001:
				motion = slide_motion.normalized() * remainder.length()
			else:
				motion = Vector3.ZERO
		elif _on_ceiling and not slide_on_ceiling:
			# Stop upward velocity on ceiling hit.
			velocity = velocity.slide(up_direction)
			motion = remainder.slide(normal)
		else:
			motion = remainder.slide(normal)
			velocity = velocity.slide(normal)

		# Enforce wall_min_slide_angle
		if _on_wall and motion_mode == MotionMode.MOTION_MODE_GROUNDED:
			if motion.length() > 0.001:
				var wall_angle := normal.angle_to(-motion.normalized())
				if wall_angle < wall_min_slide_angle:
					motion = Vector3.ZERO
					velocity = Vector3.ZERO
					break

		if motion.length() < 0.001:
			break

	# ── Extract platform velocity from floor collider ───────────────────────
	if _on_floor:
		var floor_collision := _get_floor_collision()
		if floor_collision:
			_platform_velocity = floor_collision.get_collider_velocity()
			_platform_rid = floor_collision.get_collider_rid()
			var collider := floor_collision.get_collider()
			if collider is RigidBody3D:
				_platform_angular_velocity = (collider as RigidBody3D).angular_velocity
	_prev_platform_velocity = _platform_velocity

	# ── Platform on leave ───────────────────────────────────────────────────
	if was_on_floor and not _on_floor:
		if prev_platform_vel.length() > 0.001:
			match platform_on_leave:
				PlatformOnLeave.PLATFORM_ON_LEAVE_ADD_VELOCITY:
					velocity += prev_platform_vel
				PlatformOnLeave.PLATFORM_ON_LEAVE_ADD_UPWARD_VELOCITY:
					var up_component := prev_platform_vel.dot(up_direction)
					if up_component > 0.0:
						velocity += prev_platform_vel
					else:
						velocity += prev_platform_vel - up_direction * up_component
				PlatformOnLeave.PLATFORM_ON_LEAVE_DO_NOTHING:
					pass

	# ── Floor snap ───────────────────────────────────────────────────────────
	if was_on_floor and not _on_floor and not _is_moving_upward():
		apply_floor_snap()

	# ── Real velocity ────────────────────────────────────────────────────────
	if delta > 0.0:
		_real_velocity = _position_delta / delta

	return _slide_collisions.size() > 0


## Manually snap the body to the floor. Does nothing if already on floor.
func apply_floor_snap() -> void:
	if _on_floor:
		return
	var snap_motion := -up_direction * floor_snap_length
	var collision := move_and_collide(snap_motion, false, safe_margin)
	if collision:
		var angle := collision.get_normal().angle_to(up_direction)
		if angle <= floor_max_angle:
			_on_floor = true
			_floor_normal = collision.get_normal()


# ── Query Methods ────────────────────────────────────────────────────────────

## Returns [code]true[/code] if the body is on the floor.
func is_on_floor() -> bool:
	return _on_floor

## Returns [code]true[/code] if the body is touching only the floor.
func is_on_floor_only() -> bool:
	return _on_floor and not _on_wall and not _on_ceiling

## Returns [code]true[/code] if the body is touching a wall.
func is_on_wall() -> bool:
	return _on_wall

## Returns [code]true[/code] if the body is touching only a wall.
func is_on_wall_only() -> bool:
	return _on_wall and not _on_floor and not _on_ceiling

## Returns [code]true[/code] if the body is touching the ceiling.
func is_on_ceiling() -> bool:
	return _on_ceiling

## Returns [code]true[/code] if the body is touching only the ceiling.
func is_on_ceiling_only() -> bool:
	return _on_ceiling and not _on_floor and not _on_wall

## Returns the floor collision normal. Only valid when [method is_on_floor] is [code]true[/code].
func get_floor_normal() -> Vector3:
	return _floor_normal

## Returns the floor angle in radians relative to [param custom_up].
func get_floor_angle(custom_up: Vector3 = Vector3.UP) -> float:
	if not _on_floor:
		return 0.0
	return _floor_normal.angle_to(custom_up)

## Returns the wall collision normal. Only valid when [method is_on_wall] is [code]true[/code].
func get_wall_normal() -> Vector3:
	return _wall_normal

## Returns the last partial motion applied during [method move_and_slide].
func get_last_motion() -> Vector3:
	return _last_motion

## Returns the total position change from the last [method move_and_slide].
func get_position_delta() -> Vector3:
	return _position_delta

## Returns the actual velocity after sliding (may differ from [member velocity] on slopes).
func get_real_velocity() -> Vector3:
	return _real_velocity

## Returns the linear velocity of the last contacted platform.
func get_platform_velocity() -> Vector3:
	return _platform_velocity

## Returns the angular velocity of the last contacted platform.
func get_platform_angular_velocity() -> Vector3:
	return _platform_angular_velocity

## Returns the number of collisions from the last [method move_and_slide].
func get_slide_collision_count() -> int:
	return _slide_collisions.size()

## Returns collision info by index from the last [method move_and_slide].
func get_slide_collision(index: int) -> KinematicCollision3D:
	return _slide_collisions[index]

## Returns the latest collision from the last [method move_and_slide], or [code]null[/code].
func get_last_slide_collision() -> KinematicCollision3D:
	if _slide_collisions.is_empty():
		return null
	return _slide_collisions[-1]


# ── Private Helpers ──────────────────────────────────────────────────────────

func _is_moving_upward() -> bool:
	return velocity.dot(up_direction) > 0.0


## Finds the first floor collision from the slide collisions array.
func _get_floor_collision() -> KinematicCollision3D:
	for col in _slide_collisions:
		if col.get_normal().angle_to(up_direction) <= floor_max_angle:
			return col
	return null
