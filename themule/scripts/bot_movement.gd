extends CharacterBody3D
const SPEED = 2.5

# Player settings
@export var jump_height : float = 1.0
@export var ground_offset : float = 0.5
@export var lerp_speed : float = 5.0

# Camera settings
@export var camera_sensitivity : float = 0.003
@export var camera_smoothing : float = 10.0
@export var camera_pitch : Node3D
@export var ik_container : Node3D

# Camera accumulators
var yaw_acc : float = 0
var yaw_current : float = 0
var pitch_acc : float = 0
var pitch_current : float = 0

# Other accumulators
var current_normal : Vector3 = Vector3.UP

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	
	# Camera rotation
	camera_rotation(delta)
	
	## INTERPOLATE THE TARGET NORMAL RATHER THAN THE BASIS (IN PROGRESS)
	var current_y = basis.y.normalized()
	var target_normal = ik_container.normal.normalized()
	
	# lerp the normal
	var blend = 1 - pow(0.5, delta * lerp_speed)
	current_normal = lerp(current_normal, target_normal, blend)
	
	var q_to = Quaternion(current_y, current_normal)
	transform.basis = Basis(q_to) * basis
	

func _physics_process(delta: float) -> void:
	
	# Keep at correct height
	var target_position = ik_container.average_position + transform.basis.y * ground_offset
	var distance = transform.basis.y.dot(target_position - global_position)

	
	if distance >= 0.00:
		velocity = lerp(velocity, transform.basis.y * distance * 10, delta * 10)
	elif distance < -0.01:
		velocity += get_gravity() * delta
	else:
		velocity.y = 0
	#
	## Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
		#if velocity.y >= 0 and !Input.is_action_pressed("jump"):
			#velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and distance >= -0.01:
		velocity += transform.basis.y * sqrt(jump_height * 10.0 * abs(get_gravity().y))

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	print(direction)
	if direction:
		velocity = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	# Add velocity to cast targets
	ik_container.velocity = input_dir
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	
	# Camera
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw_acc -= event.relative.x * camera_sensitivity
		pitch_acc -= event.relative.y * camera_sensitivity
		pitch_acc = clampf(pitch_acc, deg_to_rad(-89.9), deg_to_rad(89.9))
	
	if event.is_action("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func camera_rotation(delta) -> void:
	# Interoplate accumulators
	yaw_current = lerp(yaw_current, yaw_acc, camera_smoothing * delta)
	pitch_current = lerp(pitch_current, pitch_acc, camera_smoothing * delta)
	
	# reset basis
	transform.basis = Basis()
	camera_pitch.transform.basis = Basis()

	rotate_object_local(Vector3.UP, yaw_current)
	camera_pitch.rotate_object_local(Vector3.RIGHT, pitch_current)
