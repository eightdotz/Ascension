extends Node3D

@onready var lighting: Node3D = $"../../MainBody/Lighting"
@export var bad_color: Color
@export var pass_color: Color
@export var idle_animation_name = ""
@export var action_animation_name = ""
var player_detected
enum SpeedMod {SPRINT, WALL_JUMP_BOOST, BOOST, SLOW}
@onready var eyes: Array[Node] = $Construction.get_children()
@onready var light: OmniLight3D = $OmniLight3D
var player_found

var err = 0

var affecting_player := false

func _ready():
	for item in eyes:
		item.visible = false
	light.visible = false


func _detect_player(body: Node3D) -> void:
	player_found = 0
	if body.has_method("is_player"):
		body.screen_fx_enable("DontMove")
		await get_tree().create_timer(0.5).timeout
		body.screen_fx_disable("DontMove")
		await get_tree().create_timer(0.7).timeout
		var current_pos = body.global_position
		body.enable_impact()
		light.visible = true
		for item in eyes:
			item.visible = true
		var j = 20
		var stare = randi_range(0, 1)
		for i in range(0, j):
			await get_tree().create_timer(0.1).timeout
			if body.global_position != current_pos:
				player_found = 1
				if not stare:
					for item in eyes:
						item.look_at(body.global_position, Vector3.UP)
					await get_tree().create_timer(0.3).timeout
					break
				else:
					for item in eyes:
						item.look_at(body.global_position, Vector3.UP)
		if player_found:
			kill_player(body)
		
		
		light.visible = false
		body.disable_impact()
		for item in eyes:
			item.visible = false
	
func kill_player(body: Node3D) -> void:
	body.respawn_player()


func _on_detect_area_body_exited(body: Node3D) -> void:
	player_found = 0
