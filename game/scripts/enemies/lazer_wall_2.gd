extends Node3D
@onready var wall: Node3D = $".."

@onready var damage: float = 12.0
@onready var area: Area3D = $Area
@onready var knockback_force: float = 60.0

"""func _ready() -> void:
	var items = []
	for item in beams.get_children():
		items.append(item)
	
	var start = randi_range(0, items.size() - 1)
	if start > 2 and start < items.size() - 3:
			if randi_range(0, 1):
				for i in range(start, start + 3):
					items[i].queue_free()
			else:
				for i in range(start - 3, start):
					items[i].queue_free()"""

func _ready() -> void:
	area.connect("body_entered", _on_hit)

func _on_hit(body: Node3D):
	if body.has_method("is_player"):
		print("SPIKE: Hit player!")
		body.take_damage(damage)
		body.set_knockback(global_position, Vector3(knockback_force, knockback_force, knockback_force))
