extends Node3D

func _player_entered_water(body: Node3D) -> void:
	if body.has_method("is_player"):
		body.in_water = true
		print("Player entered water.")


func _player_exited_water(body: Node3D) -> void:
	if body.has_method("is_player"):
		body.in_water = false
		print("Player left water.")
