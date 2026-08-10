extends Node3D

@export var health: float = 100.0
@export var knockback_force: float = 200.0
var tween
@onready var main_body: MeshInstance3D = $MainBody
@onready var attacks = $Attacks.get_children()
@onready var timer: Timer = $Timer

@onready var ball_2: MeshInstance3D = $Ball2

signal disable_goal
signal enable_goal

var speed: float = 10.0
var target = null

func _process(delta: float) -> void:
	var rotation_vector = deg_to_rad(speed * delta)
	var ball_rotation = deg_to_rad(speed * 3 * delta)
	main_body.rotation.x += rotation_vector - randf_range(-0.001, 0.001)
	
	main_body.rotation.z += rotation_vector - randf_range(-0.001, 0.001)
	
	main_body.rotation.y += rotation_vector - randf_range(-0.001, 0.001)
	
	ball_2.rotation.z -= ball_rotation - randf_range(-0.001, 0.001)
	ball_2.rotation.x -= ball_rotation - randf_range(-0.001, 0.001)
	ball_2.rotation.y -= ball_rotation - randf_range(-0.001, 0.001)

func _on_hitbox_entered(body: Node3D) -> void:
	if body.has_method("is_player"):
		var potential_damage = body.get_velocity().length()
		if potential_damage < 100.0:
			print(potential_damage)
			return
		else:
			potential_damage = potential_damage / 2
		tween = create_tween()
		tween.tween_property(main_body, "scale", scale+Vector3(1.0, 1.0, 1.0), 0.2)
		health -= potential_damage
		print("PRIMARY CRYSTAL: Took " + str(potential_damage) + "damage")
		body.set_knockback(global_position, Vector3(knockback_force, knockback_force, knockback_force))
		if health < 0:
			visible = false
			timer.stop()
			await get_tree().create_timer(3.0).timeout
			queue_free()
		await tween.finished
		tween = create_tween()
		tween.tween_property(main_body, "scale", scale, 0.2)
		await tween.finished



func _on_player_detect_entered(body: Node3D) -> void:
	target = body
	timer.start()

func _on_timer_timeout() -> void:
	if target:
		var attack = attacks.pick_random()
		attack.start_attack(target)
