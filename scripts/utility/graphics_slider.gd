extends HScrollBar

@export_enum("LOD", "View Distance", "Brightness") var type: String
@export var label_text: String = ""
@export var metric: String = ""
@onready var label: Label = $Label

func _ready() -> void:
	label.tooltip_text = tooltip_text
	set_text(value)
	connect("value_changed", set_text)
	if not type:
		printerr("VOLUME SLIDER: Type not set, using default volume")
	if type == "LOD":
		self.value_changed.connect(Global.set_lod_value)
	elif type == "View Distance":
		self.value_changed.connect(Global.set_view_distance)
	elif type == "Brightness":
		self.value_changed.connect(Global.set_brightness)
	
func set_text(new_value: float):
	label.text = label_text + ": " + str(new_value) + metric
