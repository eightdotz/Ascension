extends HScrollBar

@export_enum("Menu", "SFX", "Ambience", "Music") var type: String

func _ready() -> void:
	if not type:
		printerr("VOLUME SLIDER: Type not set, using default volume")
	if type == "Menu":
		self.value_changed.connect(Global.set_menu_volume)
	elif type == "SFX":
		self.value_changed.connect(Global.set_sfx_volume)
	elif type == "Ambience":
		self.value_changed.connect(Global.set_level_ambience_volume)
	elif type == "Music":
		self.value_changed.connect(Global.set_level_music_volume)
