extends Node2D

# Scene objects
@export var ball_node : RigidBody2D
@export var beam_node : RigidBody2D
@export var beam_polygon : CollisionPolygon2D

# Pack parameters
@export var return_force : float = 10

# Pack variables
var beam_rotation : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	beam_rotation = -wrapf(beam_node.rotation, -PI / 2, PI / 2)

	# Positive is clockwise, negative is counterclockwise
	var lean_input : float = Input.get_action_strength("lean_right") - Input.get_action_strength("lean_left")
	if lean_input:
		beam_node.apply_torque(lean_input * 2000)
	else:
		#Apply torque to return toequilibrium point
		beam_node.apply_torque(beam_rotation * 5000)
		
		# If beam is slow, no motion is applied, and at equilibrium, stop it
		if abs(beam_node.angular_velocity) < 0.2 and abs(beam_rotation) < 0.01:
			beam_node.rotation = 0.0
			beam_node.angular_velocity = 0.0

func apply_player_motion(turn_speed) -> void:

	beam_node.apply_torque(turn_speed * 500)

func create_beam(radius : float, segments : int) -> void:
	var points = PackedVector2Array()
	points.append(Vector2(-radius, radius * .25))
	for i : float in range(segments + 1):
		var angle = PI * (i / segments)
		points.append(Vector2(-cos(angle), .5 * sin(angle) - .5) * radius)
	points.append(Vector2(radius, radius * .25))
	beam_polygon.polygon = points
