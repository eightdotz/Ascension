extends Node3D

@onready var lighting: Node3D = $"../../Lighting"
@export var bad_color: Color
@export var pass_color: Color
@export var idle_animation_name = ""
@export var action_animation_name = ""
var player_detected
enum SpeedMod {SPRINT, WALL_JUMP_BOOST, BOOST, SLOW}

var err = 0

var affecting_player := false

func _ready():
	pass



func _detect_player(body: Node3D) -> void:
	if affecting_player or not body.has_method("is_player"):
		return
	affecting_player = true
	body.add_speed_modifier(SpeedMod.SLOW, 0.0)
	body.disable_movement()
	body.impact(1.0)
	await get_tree().create_timer(1.0).timeout
	body.remove_speed_modifier(SpeedMod.SLOW)
	body.enable_movement()
	affecting_player = false


func _player_exited(body: Node3D) -> void:
	player_detected = 0
