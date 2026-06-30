extends Node3D

@export var randomize_traps: bool = false ##When using multiple traps, this randomizes them
@export var traps: Array[NodePath] = [] ##Assign the paths to traps here
@onready var start: Node3D = $Start
@onready var end: Node3D = $End
@onready var lights = $Lighting.get_children()
@onready var overlap = $OverlapChecks.get_children()
var id: int = 0

signal player_entered(id)


func _ready():
	for area in overlap:
		area.set_collision_layer_value(5, true)
		area.set_collision_mask_value(5, true)
		area.monitoring = true
		area.monitorable = true
	if randomize_traps:
		turn_off_traps()
		randomize_trap()

func set_lights(toggle: bool):
	for item in lights:
		item.set_light(toggle)

func turn_off_traps():
	print("Randomized traps ARE enabled, ensure this is intentional. Any trap assigned will be set to invisible.")
	for i in traps:
		var temp = get_node(i)
		temp.visible = false
		

func randomize_trap():
	var new_name = traps[randi_range(0, traps.size() - 1)]
	print("Selected:")
	print(name)
	var trap = get_node(new_name)
	if not trap:
		printerr("Trap not found! You have an invalid path inside of your trap randomization!")
	trap.visible = true

func get_level_type():
	return "Piece"

#func _player_entered_water(body: Node3D) -> void:
#	if body.has_method("is_player"):
#		body.in_water = true
#		print("Player entered water.")


#func _player_exited_water(body: Node3D) -> void:
#	if body.has_method("is_player"):
#		body.in_water = false
#		print("Player left water.")

func set_id(new_id: int):
	id = new_id

func get_start_transform() -> Transform3D:
	return start.transform

func get_end_transform() -> Transform3D:
	return end.transform

func _on_checkpoint_body_entered(body: Node3D) -> void:
	if body.has_method("is_player"):
		player_entered.emit(id)
	
func overlaps() -> bool:
	var found_overlap := false
	for detector in overlap:
		var collision_shape: CollisionShape3D = null
		for child in detector.get_children():
			if child is CollisionShape3D:
				collision_shape = child
				break
		if not collision_shape or not collision_shape.shape:
			printerr("OverlapCheck child is missing a CollisionShape3D!")
			continue

		var space_state = get_world_3d().direct_space_state
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = collision_shape.shape
		query.transform = collision_shape.global_transform
		query.collision_mask = detector.collision_mask
		query.exclude = [detector.get_rid()] 
		var results = space_state.intersect_shape(query, 32)
		if results.size() > 0:
			found_overlap = true
			print("Piece '%s' detector '%s' overlaps with:" % [name, detector.name])
			for result in results:
				var collider = result.collider
				if collider:
					var owner_node = collider.owner if collider.owner else collider
					print("%s (path: %s, mask: %d, layer: %d)" % [
						collider.name,
						collider.get_path(),
						collider.collision_mask,
						collider.collision_layer
					])
				else:
					print("  -> (no collider on result, rid: %s)" % str(result.get("rid")))
	return found_overlap
