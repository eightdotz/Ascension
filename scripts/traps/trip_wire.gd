extends Node3D

@export var knockback_force: float = 40.0
@export var destroy_on_end: bool = true
@export var do_damage: bool = false
@export var damage_min: float = 0.0
@export var damage_max: float = 1.0
@onready var explosion_fx: Array[Node] = $ExplosionFX.get_children()
@onready var flash: OmniLight3D = $Flash
@onready var gpu_particles_3d: GPUParticles3D = $ExplosionFX/GPUParticles3D
enum SpeedMod {SPRINT, WALL_JUMP_BOOST, BOOST, SLOW}
@onready var wire: MeshInstance3D = $Wire


func _ready() -> void:
	flash.process_mode = Node.PROCESS_MODE_DISABLED
	flash.visible = false

func flash_lights() -> void:
	flash.visible = true
	flash.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(flash, "light_energy", 16.0, 0.1)

func reset_lights() -> void:
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(flash, "light_energy", 0.0, 0.01)

	await tween.finished
	flash.process_mode = Node.PROCESS_MODE_DISABLED


func _detected(body: Node3D) -> void:
	if body.has_method("is_player"):
		await get_tree().create_timer(0.1).timeout
		flash_lights()
		wire.visible = false
		body.take_damage(randf_range(damage_min, damage_max))
		body.set_knockback(global_position, Vector3(knockback_force, knockback_force, knockback_force))
		body.add_speed_modifier(SpeedMod.SLOW, 0.8)
		body.increase_filter(0.1)
		for item in explosion_fx:
			item.emitting = true
		await get_tree().create_timer(0.2).timeout
		reset_lights()
		if destroy_on_end:
			await get_tree().create_timer(1.0).timeout
			self.queue_free()
		body.remove_speed_modifier(SpeedMod.SLOW)
		body.restore_filter(0.5)
