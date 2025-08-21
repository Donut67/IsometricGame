extends Node2D
class_name Physics3DIsometric

var real_position := Vector3.ZERO  # Real 3D position (x, y, z)
var velocity := Vector3.ZERO
var gravity := Vector3(0, 0, -25.0)  # Gravity pulls down in Z (height)

@export var bounciness := 0.0
@export var damping := 0.9
@export var terminal_velocity := -100.0
@export var friction := 5.0  # Higher means more resistance (units per second)
@export var apply_gravity := true
@export var size := Vector3.ONE

func _physics_process(delta):
	# Apply gravity
	velocity += gravity * delta
	velocity.z = max(velocity.z, terminal_velocity)

	# Move and update position
	real_position += velocity * delta

	# Handle floor collision (simple ground clamp)
	if real_position.z < 0:
		real_position.z = -0.000000001
		velocity.z = -velocity.z * bounciness
		if abs(velocity.z) < 1.0:
			velocity.z = 0
		apply_friction(delta)

	# Snap 3D position to screen (2D)
	var screen_pos: Vector2 = Global.grid_to_screen(real_position)
	z_index = round(real_position.z)
	position = screen_pos

func apply_friction(delta: float) -> void:
	var horizontal_velocity = velocity
	horizontal_velocity.z = 0
	
	var speed = horizontal_velocity.length()
	if speed > 0.001:
		var friction_force = friction * delta
		speed = max(speed - friction_force, 0)
		velocity.x = horizontal_velocity.normalized().x * speed
		velocity.y = horizontal_velocity.normalized().y * speed
	else:
		velocity.x = 0
		velocity.y = 0

func get_aabb() -> AABB:
	return AABB(real_position, size)

func intersects(other: Physics3DIsometric) -> bool:
	var _min = real_position
	var _max = real_position + size
	
	var other_min = other.real_position
	var other_max = other.real_position + other.size
	
	return (_min.x < other_max.x and _max.x > other_min.x and
			_min.y < other_max.y and _max.y > other_min.y and
			_min.z < other_max.z and _max.z > other_min.z)
