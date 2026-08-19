extends Node3D
@onready var damage: float = 12.0
@onready var beams: Node3D = $Wall/Beams
@onready var speed: float = 1.0
@onready var timer: Timer = $Timer

			
func start_attack(player: Node3D):
	attack(player, Vector3(0.0, 0.0, 0.0))
	#attack(player, Vector3(0.0, 0.0, 10.0))
	#attack(player, Vector3(0.0, 0.0, 10.0))

func attack(player: Node3D, new_pos: Vector3):
	timer.start()
	for i in range(5):
		await timer.timeout
		var new_wall = self.duplicate()
		get_tree().current_scene.add_child(new_wall)
		new_wall.global_position = global_position
		var direction = (player.global_position - global_position).normalized()
		direction.y = 0.0
		direction = direction.normalized()
		var target = new_wall.global_position + direction * 10.0
		new_wall.global_rotation = look_at(player.global_position)
		new_wall.set_view(true)
		var tween = create_tween()
		tween.tween_property(new_wall, "global_position", target, 1.0)
		await tween.finished
		new_wall.queue_free()
	timer.stop()

func set_view(toggle: bool):
	beams.visible = toggle
