extends Control
@onready var root: Node3D = $".."

func _on_menu_button_pressed() -> void:
	root.start()
