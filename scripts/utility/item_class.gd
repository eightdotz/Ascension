extends Node3D

class_name Item

var value: float
var color: Color
@export_enum("Health", "Infection", "Speed") var item_type: String

var types = ["Health", "Infection", "Speed"]

var type_colors = {"Health":Color(1.0, 0.0, 0.0), "Infection":Color(0.0, 1.0, 0.0),"Speed":Color(1.0, 0.0, 0.0)}

func get_types() -> String:
	return types

func set_options(new_value: float, new_item_type: String):
	value = new_value
	item_type = new_item_type
	color = type_colors[item_type]
