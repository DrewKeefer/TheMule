extends GPUParticles3D

@onready var gourd_tracker: Marker3D = $"../CharacterModel/YARROW_rigged/CharacterArmature_001/Skeleton3D/GourdAtt/GourdTracker"

var pack_node : Node2D
var beam_rotation : float

func _ready() -> void:
	pack_node = get_tree().get_first_node_in_group("pack_group")

func _process(delta: float) -> void:
	global_position = gourd_tracker.global_position
	global_rotation = gourd_tracker.global_rotation
	beam_rotation = pack_node.beam_rotation

	if abs(beam_rotation) <= pack_node.spill_threshold:
		emitting = false
	else:
		emitting = true
	
	amount_ratio = remap(abs(beam_rotation), pack_node.spill_threshold, PI / 2, 0.0, 1.0) * pack_node.weight
	process_material.initial_velocity = Vector2(1, 1.5) * pack_node.weight
	process_material.direction = Vector3(1 * signf(beam_rotation), 2, 0)
