extends HScrollBar

@export_enum("Menu", "SFX", "Ambience", "Music") var type: String
@export var label_text: String = ""
@export var metric: String = ""
@onready var label: Label = $Label

func _ready() -> void:
	label.tooltip_text = tooltip_text
	set_text(value)
	connect("value_changed", set_text)
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

func set_text(new_value: float):
	label.text = label_text + ": " + str(new_value) + metric
