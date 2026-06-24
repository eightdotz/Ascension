extends Node3D
var player_location: Vector3 = Vector3(0.0, 1.189, 0.466)
var player_roation: Vector3 = Vector3(0.0, 0.0, 0.0)
@onready var player: CharacterBody3D = $player

func _ready():
	player.disable_mouse()
	await player.fade_to_clear(2.0)
	player.disable_movement()
	player.toggle_mouse()
	player.enable_mouse()
	player.position = player_location
	player.rotation = player_roation
