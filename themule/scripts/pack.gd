extends Node2D

# Scene objects
@export var beam_node : RigidBody2D
@export var beam_shape : CollisionShape2D
var ui_node : Control

# Pack parameters
@export var starting_weight : float = 1.0
@export var lean_force : float = 2.0
@export var return_force : float = 1.0
@export var turn_force : float = 1.0
@export var spill_threshold : float = PI / 12.0

# Pack variables
var beam_rotation : float = 0.0
var weight_offset : float = 16.0
var spill_rate: float = 1

var weight : float :
	set(new_weight):
		if new_weight > 0:
			weight = new_weight
			beam_shape.position.y = (1 - weight) * weight_offset
			ui_node.update_weight(weight)

# Accumulators
var lean_acc : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	lean_force *= 1000
	return_force *= 1000
	turn_force *= 1000
	ui_node = get_tree().get_first_node_in_group("ui_group")
	weight = starting_weight


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	# Positive is clockwise, negative is counterclockwise
	var lean_input : float = Input.get_action_strength("lean_right") - Input.get_action_strength("lean_left")
	if lean_input:
		lean_acc += delta
		lean_acc = clampf(lean_acc, 1, 3)
		beam_node.apply_torque(lean_input * lean_force * lean_acc)
	else:
		lean_acc = move_toward(lean_acc, 0, delta * 10)
		# If beam is slow, no motion is applied, and at equilibrium, stop it
		if abs(beam_node.angular_velocity) < 0.2 and abs(beam_rotation) < 0.01:
			beam_node.angular_velocity = 0.0
			beam_node.rotation = move_toward(beam_node.rotation, 0, .01)
		else:
			#Apply torque to return to equilibrium point
			beam_node.apply_torque(beam_rotation * return_force)
	
	beam_rotation = -wrapf(beam_node.rotation, -PI / 2, PI / 2)
	
	if abs(beam_rotation) > spill_threshold:
		weight -= (spill_rate / 100) * delta * abs(beam_rotation)


func apply_player_motion(turn_speed) -> void:
	turn_speed = clampf(turn_speed, -5, 5)
	if abs(turn_speed) >= .1:
		beam_node.apply_torque(turn_speed * turn_force)


func _on_load_area_entered(new_weight: float) -> void:
	weight = new_weight
	beam_shape.position.y = (1 - weight) * weight_offset
