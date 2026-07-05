extends Node3D

@export_enum("Dungeon", "Ability", "Shop") var type: String
@export_enum("Sewer", "Fields", "Space","Tower") var biome: String
@export_group("Audio")
@export var ambience: String
@export var music: String
@export var music_interval: int = 0
@onready var pieces: Node3D = $Pieces
@onready var spawn_point: Node3D = $SpawnPoint
@onready var goal_point: Node3D = $GoalPoint
var room_cooldown = 0
var get_biome = {"Sewer":"res://scenes/biomes/sewer/", "Fields":"res://scenes/biomes/fields/", "Space":"res://scenes/biomes/space/","Tower":"res://scenes/biomes/tower/"}
var next_transform := Transform3D.IDENTITY
var spawn_amount: int
var current_id: int = 0
var avaliable_pieces: Array = []
var next_position = Vector3(0,0,0)
var spawned_pieces: Dictionary = {}
var ramp_pieces: Array = []
var player_position = 0
var last_light_position = 4
var next_piece: String

var total_spawned_pieces: int


func _ready() -> void:
	if not type:
		printerr("Level type not set!")
	if type == "Dungeon" and not biome:
		printerr("Type is of Dungeon but the Biome has not been defined. This will break!")

func spawn():
	var selected_item
	var spawn_tracker: Array = []
	
	while spawn_amount:
		await get_tree().physics_frame
		if avaliable_pieces.size() > 1:
			selected_item = avaliable_pieces.pick_random()
			if room_cooldown > 0:
				while "Room" in selected_item:
					selected_item = avaliable_pieces.pick_random()
				room_cooldown -= 1
			else:
				if "Room" in selected_item:
					room_cooldown = 4
		else:
			selected_item = avaliable_pieces[0]
		if next_piece:
			print("Swapping to overridden piece")
			selected_item = next_piece
			next_piece = ""
			
		spawn_tracker.append(selected_item)
		var piece = load(selected_item).instantiate()
		pieces.add_child(piece)
		piece.set_id(current_id)
		if current_id > 5:
			piece.set_lights(false)
		piece.player_entered.connect(_on_piece_entered)
		piece.global_transform = next_transform * piece.get_start_transform().inverse()
		next_transform = piece.get_node("End").global_transform
		await get_tree().physics_frame
		if piece.overlaps():
			piece.queue_free()
			spawn_tracker.pop_back()
			fix_overlap()
		else:
			spawn_amount -= 1
			spawned_pieces[current_id] = piece
			current_id += 1
	total_spawned_pieces = spawned_pieces.size()
	spawn_point.global_transform = spawned_pieces[0].get_node("Start").global_transform
	var end_index = spawned_pieces.keys().size() - 1
	if end_index > 0:
		goal_point.global_transform = spawned_pieces[end_index].get_node("End").global_transform
	if ambience:
		get_parent().get_parent().get_node("player").start_ambience(type, ambience, music)

func configure_spawn(amount: int, cooldown: int): ##Needs to be called by controller second
	spawn_amount = amount
	room_cooldown = cooldown

func populate(): ##Needs to be called by controller first
	var dir := DirAccess.open(get_biome[biome])
	if dir == null: printerr("Could not open folder"); return
	dir.list_dir_begin()
	for file: String in dir.get_files():
		var resource := dir.get_current_dir() + file
		print(resource)
		if "!Master" not in resource:
			if "Ramp" in resource:
				ramp_pieces.append(resource)
			else:
				avaliable_pieces.append(resource)

func get_level_type():
	if not type:
		printerr("Type not set yet! Maybe be a timing issue!")
	return type

func get_piece_start(id: int):
	return spawned_pieces[id].get_start()

func get_piece_end(id: int):
	return spawned_pieces[id].get_end()

func fix_overlap():
	print(current_id)
	print(spawned_pieces.keys())
	var previous_id = current_id - 1
	await get_tree().physics_frame
	spawned_pieces[previous_id].queue_free()
	#print(is_instance_valid(spawned_pieces[current_id]))
	spawned_pieces.erase(previous_id)

	current_id -= 1
	spawn_amount += 1

	if current_id > 0:
		next_transform = spawned_pieces[previous_id - 1].get_node("End").global_transform
	else:
		next_transform = Transform3D.IDENTITY
	if ramp_pieces:
		next_piece = ramp_pieces.pick_random()
	
func _on_piece_entered(value: int):
	player_position = value
	print("Player Position: " + str(value) + " " + str(last_light_position))
	if spawned_pieces:
		spawned_pieces[player_position].get_node("Checkpoint").queue_free()
	if player_position < last_light_position:
		return
	var future_position = player_position + 4
	if spawned_pieces.keys().max() > future_position:
		for pos in range(player_position, future_position):
			spawned_pieces[pos].set_lights(true)
			last_light_position = pos - 2
	else:
		for item in spawned_pieces.keys():
			if spawned_pieces[item].id > player_position:
				spawned_pieces[item].set_lights(true)
			
	for pos in range(0, player_position - 1):
		if spawned_pieces.has(pos):
			spawned_pieces[pos].set_lights(false)

	for index in range(0, 1):
		var oldest_key = spawned_pieces.keys().min()
		spawned_pieces[oldest_key].queue_free()
		spawned_pieces.erase(oldest_key)
