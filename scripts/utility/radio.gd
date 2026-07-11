extends Node3D

var songs = "res://audio/music/"
var pos = 0
var songs_to_load = []
@onready var audio_stream_player_3d: AudioStreamPlayer3D = $"../../AudioStreamPlayer3D"
@onready var label_3d: Label3D = $"../Label3D"

func _ready() -> void:
	populate()
	label_3d.text = "Paused"
func interact(button) -> void:
	if not songs_to_load:
		print("RADIO: No songs to play")
		return
	if button == MOUSE_BUTTON_LEFT:
		if audio_stream_player_3d.stream_paused:
			audio_stream_player_3d.stream_paused = !audio_stream_player_3d.stream_paused
			label_3d.text = "Playing " + str(pos)
			return
		print("RADIO: Playing song ", songs_to_load[pos])
		var music = load(songs_to_load[pos])
		audio_stream_player_3d.stream = music
		audio_stream_player_3d.playing = true
		pos += 1
		if pos > songs_to_load.size() - 1:
			pos = 0
		label_3d.text = "Playing " + str(pos)
	else:
		print("RADIO: Stopping songs")
		audio_stream_player_3d.stream_paused = !audio_stream_player_3d.stream_paused
		if audio_stream_player_3d.stream_paused:
			label_3d.text = "Resume"
		else:
			label_3d.text = "Playing " + str(pos)
			
func populate() -> void: 
	print("RADIO: Populating list")
	var dir := DirAccess.open(songs)
	if dir == null: printerr("RADIO:\nCould not open folder"); return
	dir.list_dir_begin()
	for file: String in dir.get_files():
		if file.ends_with(".import"):
			continue
		var resource = songs + file
		songs_to_load.append(resource)
	for i in songs_to_load:
		print("Song: ", i)
