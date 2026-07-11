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
