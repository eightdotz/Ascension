extends Node3D

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	for item in get_children():
		if item.has_method("play_test"):
			item.play_test()
			
