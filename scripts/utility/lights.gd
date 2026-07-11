extends Light3D

func _ready():
	visible = Global.opt_light_enabled
	Global.connect("light_toggled", toggle_lights)

func toggle_lights(value: bool):
	print("Toggling lights to ", str(value))
	visible = value
