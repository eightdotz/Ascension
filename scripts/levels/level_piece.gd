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
		area.collision_layer = 5
		area.collision_mask = 5
		area.monitoring = true
		area.monitorable = true
	if randomize_traps:
		turn_off_traps()
		randomize_trap()

func toggle_lights():
	for light in lights:
		light.toggle_lights()

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
	for area in overlap:
		var collision_shape = area.get_node("CollisionShape3D")
		if not collision_shape or not collision_shape.shape:
			printerr("OverlapCheck child is missing a CollisionShape3D!")
			continue

		var space_state = get_world_3d().direct_space_state
		var query = PhysicsShapeQueryParameters3D.new()
		query.shape = collision_shape.shape
		query.transform = collision_shape.global_transform
		query.collision_mask = area.collision_mask
		query.exclude = [area]

		var results = space_state.intersect_shape(query, 1)
		if results.size() > 0:
			print("Piece is overlapping: ", name)
			return true
	return false
