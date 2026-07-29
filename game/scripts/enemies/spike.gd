extends MeshInstance3D
@onready var crystal_spikes: Node3D = $".."
@onready var damage: float = 12.0
@onready var area: Area3D = $Area
@onready var knockback_force: float = 60.0
func _ready() -> void:
	area.connect("body_entered", _on_hit)

func _on_hit(body: Node3D):
	if body.has_method("is_player"):
		print("SPIKE: Hit player!")
		body.take_damage(damage)
		body.set_knockback(global_position, Vector3(knockback_force, knockback_force, knockback_force))
