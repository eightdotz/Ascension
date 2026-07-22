extends StaticBody3D


func interact(button: int):
	get_parent().queue_free()
