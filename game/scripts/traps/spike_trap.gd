extends Node3D
@export var test: bool = false
@export var spawn_amount: int = 10
@export var damage_min: float = 0.0
@export var damage_max: float = 1.0

@onready var construction: Node3D = $Construction

var rock_data: Dictionary = {}

func _ready() -> void:
	if test:
		return
	var rock
	var selected_rocks: Array = []
	var rocks = construction.get_children()
	for i in range(0, spawn_amount):
		var selection = randi_range(0, rocks.size() - 1)
		if selection not in selected_rocks:
			rock = rocks[selection]
			selected_rocks.append(selection)
		else:
			continue
		if not rock.name.begins_with("Rocks"):
			continue
		var placement_point: MeshInstance3D = rock.get_node("PlacementPoint")
		var spike: MeshInstance3D = rock.get_node("PlacementPoint/Spike")
		var damage_area: Area3D = rock.get_node("PlacementPoint/Spike/DamageArea")
		var detection_area: Area3D = rock.get_node("DetectArea")

		placement_point.visible = false

		rock_data[rock] = {
			"spike": spike,
			"particles": rock,
		}

		detection_area.body_entered.connect(_player_entered.bind(rock))
		damage_area.body_entered.connect(_damage_player.bind(rock))
	var i = 0
	for item in rocks:
		if i not in selected_rocks:
			item.queue_free()
		i += 1

func _player_entered(body: Node3D, rock: Node3D) -> void:
	if body.has_method("is_player"):
		var data = rock_data[rock]
		var spike: MeshInstance3D = data["spike"]
		var particles: GPUParticles3D = data["particles"]
		var tween = create_tween()
		tween.tween_property(spike, "position:y", spike.position.y + 8.0, 0.01)
		particles.emitting = true
		await tween.finished
		tween = create_tween()
		tween.tween_property(spike, "position:y", spike.position.y - 8.0, 0.3)

func _damage_player(body: Node3D) -> void:
	if body.has_method("is_player"):
		body.take_damage(randf_range(damage_min, damage_max))

func play_test() -> void:
	var rocks = construction.get_children()
	for rock in rocks:
		if not rock.name.begins_with("Rocks"):
			continue
		var spike: MeshInstance3D = rock.get_node("PlacementPoint/Spike")
		var tween = create_tween()
		tween.tween_property(spike, "position:y", spike.position.y + 8.0, 0.01)
		rock.emitting = true
		await tween.finished
		tween = create_tween()
		tween.tween_property(spike, "position:y", spike.position.y - 8.0, 0.3)
