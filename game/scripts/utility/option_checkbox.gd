extends CheckBox

@export_enum("Particles", "Borderless", "OptLight", "Shadows") var type: String

func _ready() -> void:
	if not type:
		printerr("OPTION CHECKBOX: Type not set, using default volume")
	if type == "Particles":
		self.toggled.connect(Global.particles)
	elif type == "Borderless":
		self.toggled.connect(Global.borderless)
	elif type == "OptLight":
		self.toggled.connect(Global.optional_lighting)
	elif type == "Shadows":
		self.toggled.connect(Global.shadows)
