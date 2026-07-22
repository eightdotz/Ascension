extends Area3D

@onready var bubble: Node3D = $"../.."

var id = 0

func erase_self():
	bubble.queue_free()
