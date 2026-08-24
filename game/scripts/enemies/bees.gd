extends Node3D
@onready var beesnest: Node3D = $".."

var player = null
enum SpeedMod {SPRINT, WALL_JUMP_BOOST, BOOST, SLOW}

@onready var bees: GPUParticles3D = $Bees
@export var damage: float = 15.0
@export var max_speed: float = 70.0
@export var acceleration: float = 50.0
@export var knockback_force: float = 10.0
var velocity: Vector3 = Vector3.ZERO
var timer: float = 5.0
func _ready() -> void:
	set_physics_process(false)

func _process(delta):
	if player == null:
		return
	timer -= 1.0 * delta
	print(timer)
	var direction = (player.global_position - global_position).normalized()
	var target_velocity = direction * max_speed
	
	velocity = velocity.move_toward(target_velocity, acceleration * delta)
	global_position += velocity * delta
	if velocity.length() > 0.1:
		look_at(global_position + velocity, Vector3.UP)
	if timer < 0:
		bees.emitting = false
		beesnest.queue_free()

func start(new_player):
	player = new_player
	set_process(true)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.has_method("is_player"):
		body.take_damage(damage)
		body.add_speed_modifier(SpeedMod.SLOW, 0.3)
		await get_tree().create_timer(1.0).timeout
		body.remove_speed_modifier(SpeedMod.SLOW)
