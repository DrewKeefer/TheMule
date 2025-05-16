extends Marker3D

@onready var is_stepping := false

var step_time : float = .2

func step(target_position):
	is_stepping = true
	
	var half_way = (global_position + target_position) / 2
	var t = get_tree().create_tween()
	t.tween_property(self, "global_position", half_way + Vector3.UP * .5, step_time)
	t.tween_property(self, "global_position", target_position, step_time)
	t.tween_callback(func(): is_stepping = false)
