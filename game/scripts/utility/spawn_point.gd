extends Node3D
@onready var visual: Node3D = $Visual


func _ready() -> void:
	visual.visible = false
