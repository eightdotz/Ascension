extends GPUParticles3D

func _ready() -> void:
	emitting = Global.particles_enabled
	Global.connect("particles_toggled", toggle_particles)

func toggle_particles(value: bool) -> void:
	print("Toggling particles to ", str(value))
	emitting = value
	visible = value
