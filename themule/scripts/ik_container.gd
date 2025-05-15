extends Node3D

var adjacent_legs = [1, 0, 3, 2]
var velocity : Vector2 = Vector2.ZERO
var normal : Vector3 = Vector3.UP
var average_position : Vector3 = Vector3.ZERO

@export var initial_curve : Path3D
@export var cast_targets : Node3D
@export var ik_targets : Node3D
@export var raycast_container : Node3D
@export var step_threshold : float = 1.5
@export var offset: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# Set starting points
	for i in range(4):
		var curve_position = initial_curve.curve.get_point_position(i)
		var raycast_child : RayCast3D = raycast_container.get_child(i)
		ik_targets.get_child(i).position = curve_position
		raycast_child.rotation = curve_position * PI / 12 + Vector3(0, -PI / 2, 0)
		raycast_child.position = curve_position
		raycast_child.translate_object_local(Vector3.UP * 2)

func _physics_process(_delta: float) -> void:
	
	for raycast_child : RayCast3D in raycast_container.get_children():
		var index = raycast_child.get_index()
		var collision_point = raycast_child.get_collision_point()
		if collision_point:
			cast_targets.get_child(index).global_position = collision_point

func _process(_delta: float) -> void:
	
	# Offset raycast based on velocity
	raycast_container.position = position + Vector3(velocity.x, 0, velocity.y) * offset
	
	
	average_position = Vector3.ZERO
	
	for i in range(4):
		
		# Check distance to cast points and step if not already doing so
		var cast_target = cast_targets.get_child(i)
		var ik_target = ik_targets.get_child(i)
		var cast_to_ik_distance = cast_target.global_position.distance_to(ik_target.global_position)
		if abs(cast_to_ik_distance) >= step_threshold and !ik_target.is_stepping:
			step_legs(i)
		
		# Calculate average position of cast_targets
		average_position += cast_target.global_position
	
	average_position = average_position / 4

func step_legs(index) -> void:
	# Get active, adjacent, and opposite legs
	var active_leg = ik_targets.get_child(index)
	var active_target = cast_targets.get_child(index)
	var adj_leg = ik_targets.get_child(adjacent_legs[index])
	var opp_leg = ik_targets.get_child(3 - index)
	var opp_target = cast_targets.get_child(3 - index)
	
	if !active_leg.is_stepping and !adj_leg.is_stepping:
		active_leg.step(active_target.global_position)
		get_quad_normal()
		if !opp_leg.is_stepping:
			opp_leg.step(opp_target.global_position)

func get_quad_normal() -> void:
	var plane_one = Plane(
		cast_targets.get_child(0).global_position,
		cast_targets.get_child(1).global_position,
		cast_targets.get_child(2).global_position
	)
	
	var plane_two = Plane(
		cast_targets.get_child(1).global_position,
		cast_targets.get_child(3).global_position,
		cast_targets.get_child(2).global_position
	)
	
	normal = ((plane_one.normal + plane_two.normal) / 2 ).normalized()
