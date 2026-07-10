extends AudioStreamPlayer3D

@export_enum("Menu", "SFX", "Ambience", "Music") var type: String

func _ready():
	if not type:
		printerr("AUDIO PLAYER 3D: Type not set, using default volume")
	if type == "Menu":
		Global.connect("menu_volume_changed", set_volume)
		set_volume(Global.menu_volume)

	elif type == "SFX":
		Global.connect("sfx_volume_changed", set_volume)
		set_volume(Global.sfx_volume)

	elif type == "Ambience":
		Global.connect("level_ambience_volume_changed", set_volume)
		set_volume(Global.level_ambience_volume)

	elif type == "Music":
		Global.connect("level_music_volume_changed", set_volume)
		set_volume(Global.level_music_volume)
	Global.connect("pause_sound", pause)

func pause():
	stream_paused = !stream_paused


func set_volume(value: float):
	print("AUDIO PLAYER 3D: Setting volume")
	volume_db = value
