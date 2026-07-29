extends Node3D
@onready var spike: MeshInstance3D = $Spike
@onready var damage: float = 32.0
@onready var light: OmniLight3D = $OmniLight3D
@onready var charging: GPUParticles3D = $Charging
@onready var preblast: GPUParticles3D = $Preblast
@onready var beam: MeshInstance3D = $Beam

func start_attack(player: Node3D):
	attack(player)

func attack(player: Node3D):
	charging.emitting = true
	await charging.finished

	var direction = (player.global_position - global_position).normalized()
	direction.y = 0.0
	direction = direction.normalized()
	global_rotation = global_rotation + Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
	charging.emitting = true
	preblast.emitting = true
	var waittime = charging.lifetime
	var tween = create_tween()
	tween.tween_property(light, "light_energy", 16.0, waittime)
	await tween.finished
