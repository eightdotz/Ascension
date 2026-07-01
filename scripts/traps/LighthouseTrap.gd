extends Node3D


@export var idle_animation_name = ""
@export var action_animation_name = ""

enum SpeedMod {SPRINT, WALL_JUMP_BOOST, BOOST, SLOW}

var err = 0

func _process(delta: float) -> void:
	
	for ray in $DetectArea/Rays.get_children():
		if ray.is_colliding():
			print("ray is colliding")
			var player = ray.get_collider()
			if player.has_method("is_player"):
				player.add_speed_modifier(SpeedMod.SLOW, 0.0)
				player.impact()
				await get_tree().create_timer(0.5).timeout
				player.remove_speed_modifier(SpeedMod.SLOW)
				await get_tree().create_timer(1.0).timeout
				break
func _ready():
	pass

func _detect_player(body: Node3D) -> void:
	pass
