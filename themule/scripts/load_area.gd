extends Area3D

@export var load_weight : float = 0.0

func _on_body_entered(body) -> void:
	var pack_node = get_tree().get_first_node_in_group("pack_group")
	pack_node._on_load_area_entered(load_weight)
