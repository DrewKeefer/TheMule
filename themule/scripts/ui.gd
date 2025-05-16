extends Control
@onready var ash_label: Label = $MarginContainer/AshLabel


func update_weight(weight):
	ash_label.text = str("ASH WEIGHT: ", snapped(weight * 100, 1))
