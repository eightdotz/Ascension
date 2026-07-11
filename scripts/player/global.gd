extends Node

var menu_volume: float = -15.0
var sfx_volume: float = -15.0
var level_ambience_volume: float = -20.0
var level_music_volume: float = -15.0
var default_gravity: float = 50.0
var particles_enabled = true
var opt_light_enabled = true

var current_floor = -1

signal menu_volume_changed(new_val: float)
signal sfx_volume_changed(new_val: float)
signal level_ambience_volume_changed(new_val: float)
signal level_music_volume_changed(new_val: float)

signal particles_toggled(opt: bool)
signal light_toggled(opt: bool)
signal pause_sound()
signal gravity_changed(amount: float)
signal load_stats
var player_stats = {}

func set_gravity(amount: float) -> void:
	gravity_changed.emit(amount)

func particles(toggled: bool) -> void:
	print("Emitting particles disabled")
	particles_enabled = toggled
	particles_toggled.emit(toggled)

func optional_lighting(toggled: bool) -> void:
	print("Emitting particles disabled")
	opt_light_enabled = toggled
	light_toggled.emit(toggled)

func borderless(toggled: bool) -> void:
	get_window().borderless = toggled

func set_menu_volume(value: float) -> void:
	menu_volume_changed.emit(value)

func set_sfx_volume(value: float) -> void:
	sfx_volume_changed.emit(value)

func set_level_ambience_volume(value: float) -> void:
	level_ambience_volume_changed.emit(value)

func set_level_music_volume(value: float) -> void:
	level_music_volume_changed.emit(value)

func save_game(dict: Dictionary):
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	for item in dict.keys():
		save_file.store_line("%s:%s" % [item, dict[item]])

func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		return
	else:
		var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
		var dict = {}
		while save_file.get_position() < save_file.get_length():
			var line: Array = save_file.get_line().rsplit(":", true, 1)
			dict[line[0]] = line[1]
			print("%s %s", line[0], line[1])
		return dict
