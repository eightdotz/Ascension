extends HScrollBar

@export_enum("LOD", "View Distance") var type: String

func _ready() -> void:
	if not type:
		printerr("VOLUME SLIDER: Type not set, using default volume")
	if type == "LOD":
		self.value_changed.connect(Global.set_lod_value)
	elif type == "View Distance":
		self.value_changed.connect(Global.set_view_distance)
