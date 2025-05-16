extends CharacterBody3D

# Scene objects
@onready var body_collision: CollisionShape3D = $BodyCollision
@onready var character_model: Node3D = $CharacterModel
@onready var character_skeleton: Skeleton3D = $CharacterModel/YARROW_rigged/CharacterArmature_001/Skeleton3D
@export var pack_node : Node2D

# Player settings
@export_category("Player Settings")
@export var SPEED : float = 5.0
@export var LEAN_STRENGTH : float = 2.5
@export var JUMP_HEIGHT : float = 2.0
@export var MOTION_INTERPOLATE_SPEED : float = 10.0
@export var ROTATION_INTERPOLATE_SPEED : float = 10.0
@export var BEAM_INFLUENCE : float = 0.5

# Player motion variables
var orientation = Transform3D()
var motion : Vector2 = Vector2()
var previous_yaw : float = 0

# Animation settins
enum ANIMATIONS {IDLE, WALK, RUN}
@onready var animation_tree: AnimationTree = $AnimationTree
@export var current_animation := ANIMATIONS.IDLE

# Camera settings
@export_category("Camera Settings")
@export var camera_sensitivity : float = 0.003
@export var camera_smoothing : float = 10.0
@export var camera_pitch : Node3D
@export var camera_yaw : Node3D

# Camera accumulators
var yaw_acc : float = 0
var yaw_current : float = 0
var pitch_acc : float = 0
var pitch_current : float = 0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Set default camera pitch
	pitch_acc = (deg_to_rad(-20))
	
	# Pre-initialize orientation transform.
	orientation = global_transform
	orientation.origin = Vector3()

func _input(event: InputEvent) -> void:
	
	# Camera
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw_acc -= event.relative.x * camera_sensitivity
		pitch_acc -= event.relative.y * camera_sensitivity
		pitch_acc = clampf(pitch_acc, deg_to_rad(-89.9), deg_to_rad(89.9))
	
	if event.is_action("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta: float) -> void:
	
	# Handle camera
	camera_rotation(delta)
	
	# Rotate player model along y axis
	var q_to = Quaternion(orientation.basis)
	var q_from = Quaternion(character_model.basis)
	var slerped_q = q_from.slerp(q_to, delta * ROTATION_INTERPOLATE_SPEED)

	character_model.basis = Basis(slerped_q)
	
	# Pass rotation speed into the pack node
	var current_yaw = character_model.rotation.y
	var delta_yaw = wrapf(current_yaw - previous_yaw, -PI, PI)
	var angular_velocity_y = delta_yaw / delta
	pack_node.apply_player_motion(-angular_velocity_y)
	previous_yaw = current_yaw
	
	# Animate
	animate(ANIMATIONS.WALK, delta)
	
	# Rotate player torso along Z axis based on pack beam rotation
	character_skeleton.reset_bone_pose(5)
	var tilted_transform = character_skeleton.get_bone_global_pose(5)
	tilted_transform = tilted_transform.rotated_local(Vector3.FORWARD, pack_node.beam_rotation)
	character_skeleton.set_bone_global_pose_override(5, tilted_transform, 1.0)
	
	# Rotate arms to side if leaning too much (Upper arm indices 11 and 15)
	var rotate_weight = abs(pack_node.beam_rotation) - .25
	character_skeleton.reset_bone_pose(11)
	character_skeleton.reset_bone_pose(15)
	var l_transform = character_skeleton.get_bone_global_pose(11)
	var r_transform = character_skeleton.get_bone_global_pose(15)
	l_transform = l_transform.rotated_local(Vector3.RIGHT, .25)
	r_transform = r_transform.rotated_local(Vector3.RIGHT, .25)
	character_skeleton.set_bone_global_pose_override(11, l_transform, rotate_weight)
	character_skeleton.set_bone_global_pose_override(15, r_transform, rotate_weight)
	
	# For rotating whole character_model
	#character_model.rotate_object_local(Vector3.FORWARD, pack_node.beam_rotation * -.07)

func _physics_process(delta: float) -> void:
	apply_basic_input(delta)
	move_and_slide()

func apply_basic_input(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	
	# Modify input_dir by beam_rotation
	var beam_rotation : float = -pack_node.beam_rotation
	if input_dir.y != 0.0:
		input_dir.x += beam_rotation * BEAM_INFLUENCE
		
	# Slow down faster than we start
	var acc_speed : float = MOTION_INTERPOLATE_SPEED
	if !input_dir.length():
		acc_speed = MOTION_INTERPOLATE_SPEED * 2
	
	motion = motion.lerp(input_dir.normalized(), acc_speed * delta)
	
	# Get camera direction
	var camera_basis : Basis = camera_yaw.global_transform.basis
	var camera_z := camera_basis.z
	var camera_x := camera_basis.x
	
	# Main motion
	
	# Create target for player to rotate towards
	var target = camera_x * input_dir.x + camera_z * input_dir.y
	if target.length() > 0.001:
		var q_from = orientation.basis.get_rotation_quaternion()
		var q_to = Transform3D().looking_at(target, Vector3.UP).basis.get_rotation_quaternion()
		orientation.basis = Basis(q_from.slerp(q_to, delta * ROTATION_INTERPOLATE_SPEED))
	
	# Apply movement based on orientation of camera
	var direction = (camera_basis * Vector3(motion.x, 0, motion.y))
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	
	# Apply beam influence
	if abs(beam_rotation) >= PI / 4:
		velocity += orientation.basis.x * beam_rotation

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = sqrt(JUMP_HEIGHT * 2 * abs(get_gravity().y))

func camera_rotation(delta) -> void:
	# Interoplate accumulators
	yaw_current = lerp(yaw_current, yaw_acc, camera_smoothing * delta)
	pitch_current = lerp(pitch_current, pitch_acc, camera_smoothing * delta)
	
	# reset basis
	camera_yaw.transform.basis = Basis()
	camera_pitch.transform.basis = Basis()

	camera_yaw.rotate_object_local(Vector3.UP, yaw_current)
	camera_pitch.rotate_object_local(Vector3.RIGHT, pitch_current)

func animate(anim: int, delta := 0.0):
	current_animation = anim
	animation_tree["parameters/walk/blend_position"] = velocity.length()
