extends Node3D

@onready var break_fx: GPUParticles3D = $Break
@onready var bee_control: Node3D = $BeeControl
@onready var nest: MeshInstance3D = $Nest

func _ready() -> void:
	var new_size = randf_range(-0.5, 0.5)
	var new_x = randf_range(-0.1, 0.1)
	var new_y = randf_range(-0.1, 0.1)
	var new_z = randf_range(-0.1, 0.1)
	nest.scale += Vector3(new_x + new_size, new_y + new_size, new_z + new_size)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("is_player"):
		break_fx.emitting = true
		bee_control.start(body)
		nest.visible = false
		await break_fx.finished
