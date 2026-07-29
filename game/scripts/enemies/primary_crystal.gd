extends Node3D

@export var health: float = 100.0
@export var knockback_force: float = 200.0
var tween
@onready var main_body: MeshInstance3D = $MainBody
@onready var attacks = $Attacks.get_children()
@onready var timer: Timer = $Timer
var target = null

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
		await attack.attack(target)
