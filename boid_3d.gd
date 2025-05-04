extends CharacterBody3D

# Flight parameters
@export var max_speed: float = 8.0
@export var min_speed: float = 4.0
@export var maneuverability: float = 2.5
@export var bank_amount: float = 0.5
@export var avoidance_force: float = 5.0
@export var avoidance_distance: float = 3.0
@export var wander_strength: float = 0.3
@export var change_direction_time: float = 2.0

# Internal variables
var _current_velocity: Vector3 = Vector3.ZERO
var _target_direction: Vector3 = Vector3.FORWARD
var _wander_timer: float = 0.0
var _random_wander: Vector3 = Vector3.ZERO

# Get references to all raycasts and wings directly
@onready var raycasts: Array[RayCast3D] = [
	$RayCast3D,
	$RayCast3D2,
	$RayCast3D3,
	$RayCast3D4,
	$RayCast3D5,
	$RayCast3D6
]

@onready var wing1: MeshInstance3D = $wing1
@onready var wing2: MeshInstance3D = $wing2

func _ready():
	# Initialize with random direction and speed
	_current_velocity = Vector3.FORWARD.rotated(Vector3.UP, randf_range(0, TAU)) * min_speed
	_target_direction = _current_velocity.normalized()
	_reset_wander_timer()
	
	# Setup all raycasts for avoidance
	for ray in raycasts:
		if ray:
			ray.target_position = Vector3.FORWARD * avoidance_distance
			ray.enabled = true

func _physics_process(delta):
	# Update wander behavior
	_wander_timer -= delta
	if _wander_timer <= 0:
		_random_wander = Vector3(
			randf_range(-1, 1),
			randf_range(-0.2, 0.5),  # Slight upward bias
			randf_range(-1, 1)
		).normalized()
		_reset_wander_timer()
	
	# Calculate avoidance
	var avoidance = _calculate_avoidance()
	
	# Combine behaviors
	var desired_direction = (_target_direction * (1.0 - wander_strength) + 
						  _random_wander * wander_strength + 
						  avoidance).normalized()
	
	# Smoothly adjust direction
	_target_direction = _target_direction.lerp(desired_direction, delta * maneuverability)
	
	# Adjust velocity
	_current_velocity = _current_velocity.lerp(_target_direction * max_speed, delta * maneuverability)
	
	# Apply banking rotation to wings
	var bank_rotation = -_current_velocity.signed_angle_to(_target_direction, Vector3.UP) * bank_amount
	wing1.rotation.z = lerp(wing1.rotation.z, bank_rotation, delta * 5.0)
	wing2.rotation.z = lerp(wing2.rotation.z, bank_rotation, delta * 5.0)
	
	# Move the bat with collision
	velocity = _current_velocity
	move_and_slide()
	
	# Face direction of movement
	if velocity.length() > 0.1:
		var target_rotation = atan2(-velocity.x, -velocity.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 2.0)

func _calculate_avoidance() -> Vector3:
	var avoidance_vector = Vector3.ZERO
	
	for ray in raycasts:
		if ray and ray.is_colliding():
			var distance = global_position.distance_to(ray.get_collision_point())
			var strength = 1.0 - (distance / avoidance_distance)
			avoidance_vector += (global_position - ray.get_collision_point()).normalized() * strength
	
	return avoidance_vector * avoidance_force

func _reset_wander_timer():
	_wander_timer = randf_range(change_direction_time * 0.5, change_direction_time * 1.5)

func _on_visible_on_screen_notifier_screen_exited():
	# When bat goes off-screen, teleport to opposite side (optional)
	var viewport = get_viewport().get_camera_3d()
	if viewport:
		var screen_pos = viewport.unproject_position(global_position)
		var new_pos = global_position
		
		if screen_pos.x < 0:
			new_pos.x = -new_pos.x
		elif screen_pos.x > viewport.size.x:
			new_pos.x = -new_pos.x
			
		if screen_pos.y < 0:
			new_pos.y = -new_pos.y
		elif screen_pos.y > viewport.size.y:
			new_pos.y = -new_pos.y
			
		global_position = new_pos
