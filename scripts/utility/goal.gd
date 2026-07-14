extends Node3D

@export var visible_to_player: bool = true
@onready var visual: MeshInstance3D = $Goal/GoalArea/Visual

signal level_completed

func _ready() -> void:
	if not visible_to_player:
		visual.visible = false


func _on_entered(body: Node3D) -> void:
	if body.has_method("is_player"):
		emit_signal("level_completed")

func disable() -> void:
	self.visible = false
	
func enable() -> void:
	self.visible = true
