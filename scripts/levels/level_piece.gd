extends Node3D

@export var randomize_traps: bool = false ##When using multiple traps, this randomizes them
@export var traps: Array[NodePath] = [] ##Assign the paths to traps here
@onready var start: Node3D = $Start
@onready var end: Node3D = $End
@onready var lights = $MainBody/Lighting.get_children()
@onready var overlap = $OverlapChecks.get_children()

var pulse_time := 0.0
@export_group("Emergency Settings")
@export var min_energy := 0.2
@export var max_energy := 5.0
@export var pulse_speed := 4.0

var id: int = 0

signal player_entered(id)
var color: Color

func _ready() -> void:
	set_process(false)
	if randomize_traps:
		turn_off_traps()
		await get_tree().process_frame
		randomize_trap()
		

func _process(delta):
	pulse_time += delta * pulse_speed

	var energy = lerp(
		min_energy,
		max_energy,
		(sin(pulse_time) + 1.0) / 2.0
	)

	for light in lights:
		if is_instance_valid(light):
			light.energy = energy

func set_lights(toggle: bool) -> void:
	for item in lights:
		if is_instance_valid(item):
			item.set_light(toggle)

func turn_off_traps() -> void:
	for i in traps:
		var temp = get_node(i)
		temp.visible = false
		temp.disable_hitbox()
		

func randomize_trap() -> void:
	print("LEVEL_PIECE: Randomizing traps")
	var new_name = traps[randi_range(0, traps.size() - 1)]
	print("LEVEL_PIECE\nSelected ", new_name)
	var trap = get_node(new_name)
	
	trap.enable_hitbox()
	print("LEVEL_PIECE")
	for item in traps:
		if item != new_name:
			print("Freeing ", item)
			get_node(item).queue_free()
	trap.visible = true
	print(trap.name + " set to: " + str(trap.visible))

func get_level_type() -> String:
	return "Piece"

#func _player_entered_water(body: Node3D) -> void:
#	if body.has_method("is_player"):
#		body.in_water = true
#		print("Player entered water.")


#func _player_exited_water(body: Node3D) -> void:
#	if body.has_method("is_player"):
#		body.in_water = false
#		print("Player left water.")

func set_id(new_id: int) -> void:
	id = new_id

func get_start_transform() -> Transform3D:
	return start.transform

func get_end_transform() -> Transform3D:
	return end.transform

func _on_checkpoint_body_entered(body: Node3D) -> void:
	if body.has_method("is_player"):
		player_entered.emit(id)

func _get_query_shape(collision_shape: CollisionShape3D) -> Dictionary:
	var shape = collision_shape.shape
	var query_transform = collision_shape.global_transform
	if shape is ConcavePolygonShape3D:
		var faces: PackedVector3Array = shape.get_faces()
		if faces.size() > 0:
			var aabb := AABB(faces[0], Vector3.ZERO)
			for v in faces:
				aabb = aabb.expand(v)
			var box := BoxShape3D.new()
			box.size = aabb.size
			query_transform = query_transform * Transform3D(Basis.IDENTITY, aabb.get_center())
			return {"shape": box, "transform": query_transform}
	return {"shape": shape, "transform": query_transform}

func overlaps() -> bool:
	
	var found_overlap := false
	for detector in overlap:
		detector.set_collision_layer_value(5, true)
		detector.set_collision_mask_value(5, true)

		var collision_shape: CollisionShape3D = null
		for child in detector.get_children():
			if child is CollisionShape3D:
				collision_shape = child
				break
		if not collision_shape or not collision_shape.shape:
			printerr("LEVEL_PIECE:\nOverlapCheck child is missing a CollisionShape3D!")
			continue

		var qs = _get_query_shape(collision_shape)
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = qs.shape
		query.transform = qs.transform
		query.collision_mask = detector.collision_mask
		query.collide_with_areas = true
		query.exclude = [detector.get_rid()]
		var results = space_state.intersect_shape(query, 64)
		if results.size() > 0:
			print("LEVEL_PIECE: Overlap found!")
			found_overlap = true
			print("LEVEL_PIECE: Piece '%s' detector '%s' overlaps with:" % [name, detector.name])
			for result in results:
				var collider = result.collider
				if collider:
					print("LEVEL_PIECE: %s (path: %s, mask: %d, layer: %d)" % [
						collider.name, collider.get_path(),
						collider.collision_mask, collider.collision_layer
					])
	return found_overlap
	
func set_light_color(new_color: Color):
	for item in lights:
		item.color = new_color
func remove_lights():
	for item in lights:
		item.queue_free()
func get_light_color():
	if lights:
		if is_instance_valid(lights[0]):
			color = lights[0].color
			return lights[0].color
func get_light_energy():
	if lights:
		if is_instance_valid(lights[0]):
			return lights[0].energy
func start_failure():
	set_process(true)
