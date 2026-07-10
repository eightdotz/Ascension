extends GPUParticles3D

func _ready():
	emitting = Global.particles_enabled
	Global.connect("particles_toggled", toggle_particles)

func toggle_particles(value: bool):
	print("Toggling particles to ", str(value))
	emitting = value
