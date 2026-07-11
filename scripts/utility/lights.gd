extends Light3D

func _ready() -> void:
	visible = Global.opt_light_enabled
	Global.connect("light_toggled", toggle_lights)

func toggle_lights(value: bool) -> void:
	print("Toggling lights to ", str(value))
	visible = value
