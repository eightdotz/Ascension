extends Node3D

@onready var visual: MeshInstance3D = $Goal/GoalArea/Visual

func _ready():
	visual.visible = false


func _on_entered(body: Node3D) -> void:
	if body.has_method("is_player"):
		await body.fade_to_black()
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main/AbilitySelection.tscn")
