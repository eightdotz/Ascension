@tool
extends MeshInstance3D

@export var toggle: bool = true:
	set(value):
		toggle = value
		_update()

@export var light: Light3D


@export_group("Light Physics")
@export var range := 10.0:
	set(value):
		range = value
		_update()

@export var attenuation := 1.0:
	set(value):
		attenuation = value
		_update()

@export var angle := 45.0:
	set(value):
		angle = value
		_update()

@export_group("Light Attributes")
@export var color := Color.WHITE:
	set(value):
		color = value
		_update()

@export var energy := 1.0:
	set(value):
		energy = value
		_update()

func _ready():
	_update()

func _update():
	if !is_node_ready():
		return
	if light is SpotLight3D:
		light.visible = toggle
		light.spot_range = range
		light.spot_angle = angle
		light.spot_attenuation = attenuation
		light.light_color = color
		light.light_energy = energy
	elif light is OmniLight3D:
		light.visible = toggle
		light.omni_range = range
		light.omni_attenuation = attenuation
		light.light_color = color
		light.light_energy = energy
	if mesh and mesh.material:
		mesh.material.emission = color

func set_light(toggle: bool):
	light.visible = toggle
