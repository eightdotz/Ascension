extends Node

var menu_volume: float = -15.0
var sfx_volume: float = -15.0
var level_ambience_volume: float = -20.0
var level_music_volume: float = -15.0
var particles_enabled = true
signal menu_volume_changed(new_val: float)
signal sfx_volume_changed(new_val: float)
signal level_ambience_volume_changed(new_val: float)
signal level_music_volume_changed(new_val: float)

signal particles_toggled(opt: bool)

signal pause_sound()

func particles(toggled: bool):
	print("Emitting particles disabled")
	particles_enabled = toggled
	particles_toggled.emit(toggled)

func set_menu_volume(value: float) -> void:
	menu_volume_changed.emit(value)

func set_sfx_volume(value: float) -> void:
	sfx_volume_changed.emit(value)

func set_level_ambience_volume(value: float) -> void:
	level_ambience_volume_changed.emit(value)

func set_level_music_volume(value: float) -> void:
	level_music_volume_changed.emit(value)
