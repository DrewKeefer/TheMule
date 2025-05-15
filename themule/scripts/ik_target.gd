extends Marker3D

@onready var is_stepping := false

func step(target_position):
	is_stepping = true
	
	var half_way = (global_position + target_position) / 2
	var t = get_tree().create_tween()
	t.tween_property(self, "global_position", half_way + Vector3.UP, 0.1)
	t.tween_property(self, "global_position", target_position, 0.1)
	t.tween_callback(func(): is_stepping = false)
