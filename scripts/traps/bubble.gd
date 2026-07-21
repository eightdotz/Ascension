extends Node3D
@export var damage_min: float = 5.0
@export var damage_max: float = 5.0
@export var knockback_force: float = 50.0

@export var rise_speed := 0.8
@export var drift_strength := 0.2

var time := randf() * TAU

func _ready() -> void:
	rise_speed = randf_range(0.6, 1.2)
	drift_strength = randf_range(0.1, 0.3)
	scale *= randf_range(0.8, 1.5)
	set_process(!is_processing())
	
func _process(delta):
	time += delta

	global_position.y += rise_speed * delta
	global_position.x += sin(time) * drift_strength * delta
	global_position.z += cos(time * 0.8) * drift_strength * delta

func _on_area_3d_body_entered(body: Node3D) -> void:
	var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
	var gpu_particles_3d: GPUParticles3D = $MeshInstance3D/GPUParticles3D
	if body.has_method("is_player"):
		var material := mesh_instance_3d.get_active_material(0) as StandardMaterial3D
		var tween = create_tween()
		body.take_damage(randf_range(damage_min, damage_max))
		body.set_knockback(global_position, Vector3(knockback_force, knockback_force, knockback_force))
		tween.set_parallel()
		gpu_particles_3d.emitting = true
		tween.tween_property(mesh_instance_3d, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
		tween.tween_property(material, "emission", Color(0.0, 0.0, 0.0, 0.0), 0.1)
		tween.tween_property(material, "albedo_color", Color(0.0, 0.0, 0.0, 0.0), 0.1)
		await tween.finished
		await gpu_particles_3d.finished
		queue_free()
		


func play_test() -> void:
	set_process(!is_processing())
	var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
	var gpu_particles_3d: GPUParticles3D = $MeshInstance3D/GPUParticles3D
	var material := mesh_instance_3d.get_active_material(0) as StandardMaterial3D
	var tween = create_tween()
	tween.set_parallel()
	gpu_particles_3d.emitting = true
	tween.tween_property(mesh_instance_3d, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
	tween.tween_property(material, "emission", Color(0.0, 0.0, 0.0, 0.0), 0.1)
	tween.tween_property(material, "albedo_color", Color(0.0, 0.0, 0.0, 0.0), 0.1)

func placeholder(body: Node3D) -> void:
	set_process(!is_processing())
	
func placeholder_2(body: Node3D) -> void:
	queue_free()
