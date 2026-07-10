extends CheckBox

@export_enum("Particles") var type: String

func _ready():
	if not type:
		printerr("OPTION CHECKBOX: Type not set, using default volume")
	if type == "Particles":
		self.toggled.connect(Global.particles)
