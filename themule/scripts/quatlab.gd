extends MeshInstance3D

@onready var base: MeshInstance3D = $"../Base"
@onready var normal: MeshInstance3D = $"../Normal"

# Camera accumulators

@export var camera_sensitivity : float = 0.003
@export var camera_smoothing : float = 10.0
@export var lerpSpeed : float = 0.5;

var yaw_acc : float = 0
var yaw_current : float = 0
var pitch_acc : float = 0
var pitch_current : float = 0
var current_normal : Vector3 = Vector3.UP

var lean_acc : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Camera rotation
	camera_rotation(delta)
	
	## COPIES AND SLERPS OBJECTS ORIENTATION (WORKS)
	#var q_to = base.basis.get_rotation_quaternion()
	#var q_from = basis.get_rotation_quaternion()
	#var q_slerp = q_from.slerp(q_to, delta * 10)
	#transform.basis = Basis(q_slerp)
	
	## LOCKS Y AXIS TO THAT OF NORMAL (WORKS)
	#var current_y = base.basis.y.normalized()
	#var target_normal = normal.basis.y.normalized()
	#
	#var q_to = Quaternion(current_y, target_normal)
	#var q_from = Quaternion(base.basis)
	#basis = Basis(q_to) * base.basis
	
	## INTERPOLATE THE TARGET NORMAL RATHER THAN THE BASIS (WORKS)
	var current_y = base.basis.y.normalized()
	var target_normal = normal.basis.y.normalized()
	
	# lerp the normal
	var blend = 1 - pow(0.5, delta * lerpSpeed)
	current_normal = lerp(current_normal, target_normal, blend)
	
	var q_to = Quaternion(current_y, current_normal)
	base.basis = Basis(q_to) * base.basis
	
	
func _input(event: InputEvent) -> void:
	
	# Camera
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw_acc -= event.relative.x * camera_sensitivity
		pitch_acc -= event.relative.y * camera_sensitivity

	if event.is_action("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func camera_rotation(delta) -> void:
	# Interoplate accumulators
	yaw_current = lerp(yaw_current, yaw_acc, camera_smoothing * delta)
	pitch_current = lerp(pitch_current, pitch_acc, camera_smoothing * delta)
	
	# reset basis
	base.transform.basis = Basis()

	base.rotate_object_local(Vector3.UP, yaw_current)
	base.rotate_object_local(Vector3.RIGHT, pitch_current)


func _on_timer_timeout() -> void:
	lean_acc += deg_to_rad(30)
	normal.basis = Basis(Vector3.RIGHT, lean_acc)
	

func rotate_with_beam() -> void:
	
	## INTERPOLATE THE TARGET NORMAL RATHER THAN THE BASIS (WORKS)
	#var beam_basis = Basis(Vector3.BACK, pack_node.beam_rotation)
	#
	#var current_y = body_collision.basis.y.normalized()
	#var target_normal = beam_basis.y.normalized()

	#
	## lerp the normal
	#var blend = 1 - pow(0.5, delta * 5)
	#current_normal = lerp(current_normal, target_normal, blend)
	#
	#var q_normal_to = Quaternion(current_y, current_normal)
	#body_collision.basis = Basis(q_to) * body_collision.basis
	
	pass
	
