extends Node3D
@onready var spike: MeshInstance3D = $Spike
@onready var timer: Timer = $Timer
@onready var timer_2: Timer = $Timer2
@onready var damage: float = 12.0
func start_attack(player: Node3D):
	attack(player, Vector3(0.0, 0.0, 0.0))
	#attack(player, Vector3(0.0, 0.0, 10.0))
	#attack(player, Vector3(0.0, 0.0, 10.0))

func attack(player: Node3D, new_pos: Vector3):
	var spikes = []
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0.0
	direction = direction.normalized()
	var distance := 0.0
	timer.start()
	for i in range(15):
		await timer.timeout
		var new_spike = spike.duplicate()
		get_tree().current_scene.add_child(new_spike)

		distance += randf_range(4.0, 6.0)
		var sway = Vector3(randf_range(1.0, 4.0), 0.0, randf_range(1.0, 4.0))
		#var forward = -global_transform.basis.z
		new_spike.global_position = (global_position + new_pos + sway) + direction * distance
		new_spike.global_rotation = global_rotation + Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
		new_spike.visible = true
		spikes.append(new_spike)
	timer.stop()
	timer_2.start()
	for item in spikes.duplicate():
		await timer_2.timeout
		item.queue_free()
	timer_2.stop()
