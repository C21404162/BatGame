extends CharacterBody3D

# Flight parameters
@export var max_speed: float = 9.0
@export var min_speed: float = 5.0
@export var acceleration: float = 5.0
@export var bank_amount: float = 0.6
@export var avoidance_force: float = 10.0
@export var avoidance_distance: float = 3.0
@export var wander_strength: float = 0.15
@export var max_vertical_change: float = 0.8
@export var vertical_speed: float = 3.5

# Internal variables - ALL declared here
var _current_velocity: Vector3 = Vector3.ZERO
var _target_direction: Vector3 = Vector3.FORWARD
var _wander_timer: float = 0.0
var _flap_timer: float = 0.0
var _current_vertical: float = 0.0
var _random_wander: Vector3 = Vector3.ZERO 
@onready var raycasts: Array[RayCast3D] = [
	$RayCast3D, $RayCast3D2, $RayCast3D3,
	$RayCast3D4, $RayCast3D5, $RayCast3D6
]
@onready var wing1: MeshInstance3D = $wing1
@onready var wing2: MeshInstance3D = $wing2

var is_grabbed := false
var grabber_id := -1  # -1 = not grabbed, 0 = left hand, 1 = right hand

func grab(hand_id: int):
	is_grabbed = true
	grabber_id = hand_id
	collision_layer = 0  # Disable all collisions
	collision_mask = 0
	
func release():
	is_grabbed = false
	grabber_id = -1
	collision_layer = 1  # Re-enable world collisions
	collision_mask = 1
	velocity = Vector3.ZERO

func _ready():
	_current_velocity = Vector3.FORWARD.rotated(Vector3.UP, randf_range(0, TAU)) * min_speed
	_target_direction = _current_velocity.normalized()
	_reset_wander_timer()
	
	for ray in raycasts:
		if ray:
			ray.target_position = Vector3.FORWARD * avoidance_distance
			ray.enabled = true

func _physics_process(delta):
	
	if is_grabbed:
		return  # Skip all movement when grabbed
	
	_wander_timer -= delta
	_flap_timer += delta * 8.0
	_current_vertical = sin(_flap_timer) * max_vertical_change
	
	if _wander_timer <= 0:
		_random_wander = Vector3(  # Now properly declared
			randf_range(-1.2, 1.2),
			randf_range(-0.3, 0.4),
			randf_range(-1.2, 1.2)
		).normalized()
		_reset_wander_timer()
	
	var avoidance = _calculate_avoidance() * 2.0
	var desired_direction = (
		_target_direction * (1.0 - wander_strength) + 
		_random_wander * wander_strength + 
		avoidance
	).normalized()
	
	_target_direction = _target_direction.slerp(desired_direction, delta * acceleration)
	var base_velocity = _target_direction * lerp(min_speed, max_speed, 0.8)
	_current_velocity = _current_velocity.lerp(
		base_velocity + Vector3.UP * _current_vertical, 
		delta * acceleration
	)
	
	var bank_rotation = -_current_velocity.signed_angle_to(_target_direction, Vector3.UP) * bank_amount
	wing1.rotation.z = lerp(wing1.rotation.z, bank_rotation, delta * 10.0)
	wing2.rotation.z = lerp(wing2.rotation.z, bank_rotation, delta * 10.0)
	
	wing1.rotation.x = sin(_flap_timer * 1.5) * 0.4
	wing2.rotation.x = sin(_flap_timer * 1.5 + PI) * 0.4
	
	velocity = _current_velocity
	move_and_slide()
	
	if velocity.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-velocity.x, -velocity.z), delta * 6.0)

func _calculate_avoidance() -> Vector3:
	var avoidance = Vector3.ZERO
	for ray in raycasts:
		if ray and ray.is_colliding():
			var dist = global_position.distance_to(ray.get_collision_point())
			var strength = 1.0 - (dist / avoidance_distance)
			avoidance += (global_position - ray.get_collision_point()).normalized() * strength
	return avoidance.normalized()

func _reset_wander_timer():
	_wander_timer = randf_range(0.8, 1.2)
