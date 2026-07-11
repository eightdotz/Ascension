extends CheckBox

@export_enum("Particles", "Borderless", "OptLight") var type: String

func _ready():
	if not type:
		printerr("OPTION CHECKBOX: Type not set, using default volume")
	if type == "Particles":
		self.toggled.connect(Global.particles)
	elif type == "Borderless":
		self.toggled.connect(Global.borderless)
	elif type == "OptLight":
		self.toggled.connect(Global.optional_lighting)
		
