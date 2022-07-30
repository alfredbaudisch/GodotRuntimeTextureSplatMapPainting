extends KinematicBody

export var max_speed = 10
export var acceleration = 70
export var friction = 60
export var air_friction = 10
export var gravity = -40
export var jump_impulse = 20
export var mouse_sensitivity = .1
export var controller_sensitivity = 3
export var rot_speed = 5
export (int, 0, 10) var push = 1

var velocity = Vector3.ZERO
var snap_vector = Vector3.ZERO

onready var spring_arm = $SpringArm
onready var pivot = $Pivot
onready var camera = $SpringArm/Camera

func _ready():
	Engine.set_target_fps(144)
	Engine.set_iterations_per_second(144)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
#	Globalsettings.connect("fov_updated", self, "_on_fov_updated")
#	Globalsettings.connect("mouse_sens_updated", self, "_on_mouse_sens_updated")
	
func _unhandled_input(event):	
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		spring_arm.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))		
	pass

func _physics_process(delta):
	var input_vector = get_input_vector()
	var direction = get_direction(input_vector)
	apply_movement(input_vector, direction, delta)
	apply_friction(direction, delta)
	apply_gravity(delta)
	update_snap_vector()
	jump()
	apply_controller_rotation()
#	rotate_player()

	spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg2rad(-75), deg2rad(75))

	velocity = move_and_slide_with_snap(velocity, snap_vector, Vector3.UP, true, 4, 0.785398, false)
#	for idx in get_slide_count():
#		var collision = get_slide_collision(idx)
#		if collision.collider.is_in_group("bodies"):
#			collision.collider.apply_central_impulse(-collision.normal * velocity.length() * push)
	
#func rotate_player():
#	rotate_y(deg2rad(joystickRight.get_output().x * mouse_sensitivity))
#	spring_arm.rotate_x(deg2rad(joystickRight.get_output().y * mouse_sensitivity))	
	
func get_input_vector():
	var input_vector = Vector3.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.z = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	return input_vector.normalized() if input_vector.length() > 1 else input_vector
	
	
func get_direction(input_vector):
	var direction = (input_vector.x * transform.basis.x) + (input_vector.z * transform.basis.z)
	return direction
	
	
func apply_movement(input_vector, direction, delta):
	if direction != Vector3.ZERO:
		velocity.x = velocity.move_toward(direction * max_speed, acceleration * delta).x
		velocity.z = velocity.move_toward(direction * max_speed, acceleration * delta).z
#		pivot.look_at(global_transform.origin + direction, Vector3.UP)
		pivot.rotation.y = lerp_angle(pivot.rotation.y, atan2(-input_vector.x, -input_vector.z), rot_speed * delta)
		
func apply_friction(direction, delta):
	if direction == Vector3.ZERO:
		if is_on_floor():
			velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
		else:
			velocity.x = velocity.move_toward(Vector3.ZERO, air_friction * delta).x
			velocity.z = velocity.move_toward(Vector3.ZERO, air_friction * delta).z
		
func apply_gravity(delta):
	velocity.y += gravity * delta
	velocity.y = clamp(velocity.y, gravity, jump_impulse)
	
	
func update_snap_vector():
	snap_vector = -get_floor_normal() if is_on_floor() else Vector3.DOWN
	
	
func jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		snap_vector = Vector3.ZERO
		velocity.y = jump_impulse
	if Input.is_action_just_released("jump") and velocity.y > jump_impulse / 2:
		velocity.y = jump_impulse / 2
		
		
func apply_controller_rotation():
	var axis_vector = Vector2.ZERO
	axis_vector.x = Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	axis_vector.y = Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	
	if InputEventJoypadMotion:
		rotate_y(deg2rad(-axis_vector.x) * controller_sensitivity)
		spring_arm.rotate_x(deg2rad(-axis_vector.y) * controller_sensitivity)
		
		
func _on_fov_updated(value):
	camera.fov = value
	
	
func _on_mouse_sens_updated(value):
	mouse_sensitivity = value
		




