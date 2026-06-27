extends Node3D

@export_enum("Dungeon", "Ability", "Shop") var type: String
@export_enum("Sewer", "Fields", "Space","Tower") var biome: String
@onready var pieces: Node3D = $Pieces
@onready var spawn_point: Node3D = $SpawnPoint
@onready var goal_point: Node3D = $GoalPoint
var skip_testing = 1

var get_biome = {"Sewer":"res://scenes/biomes/sewer/", "Fields":"res://scenes/biomes/fields/", "Space":"res://scenes/biomes/space/","Tower":"res://scenes/biomes/tower/"}

var spawn_amount: int
var current_id: int = 0
var avaliable_pieces: Array = []
var next_position = Vector3(0,0,0)
var spawned_pieces: Dictionary = {}

func _ready() -> void:
	if not type:
		printerr("Level type not set!")
	if type == "Dungeon" and not biome:
		printerr("Type is of Dungeon but the Biome has not been defined. This will break!")

func spawn():
	var selected_item
	var next_transform := Transform3D.IDENTITY
	var selection
	var spawn_tracker: Array = []
	while spawn_amount:
		if avaliable_pieces.size() > 1:
			selection = randi_range(0, avaliable_pieces.size())
			selected_item = avaliable_pieces[selection - 1]
			if skip_testing:
				if "-" in selected_item:
					continue
			if current_id == 0 or current_id == 1 or "Room" in spawn_tracker[spawn_tracker.size() - 1]:
				while "Room" in selected_item:
					selection = randi_range(0, avaliable_pieces.size())
					selected_item = avaliable_pieces[selection - 1]
		else:
			selected_item = avaliable_pieces[0]
		spawn_tracker.append(selected_item)
		var piece = load(selected_item).instantiate()
		pieces.add_child(piece)
		piece.set_id(current_id)
		
		piece.global_transform = next_transform * piece.get_start_transform().inverse()
		next_transform = piece.get_node("End").global_transform
		#if randi_range(0, 1):
		#	if "Room" not in selected_item:
		#		piece.rotation.y += 180
		spawn_amount -= 1
		spawned_pieces[current_id] = piece
		current_id += 1

	spawn_point.global_transform = spawned_pieces[0].get_node("Start").global_transform
	var end_index = spawned_pieces.keys().size() - 1
	if end_index > 0:
		goal_point.global_transform = spawned_pieces[end_index].get_node("End").global_transform

func configure_spawn(amount: int): ##Needs to be called by controller second
	spawn_amount = amount

func populate(): ##Needs to be called by controller first
	var dir := DirAccess.open(get_biome[biome])
	if dir == null: printerr("Could not open folder"); return
	dir.list_dir_begin()
	for file: String in dir.get_files():
		var resource := dir.get_current_dir() + file
		print(resource)
		avaliable_pieces.append(resource)

func get_level_type():
	if not type:
		printerr("Type not set yet! Maybe be a timing issue!")
	return type

func get_piece_start(id: int):
	return spawned_pieces[id].get_start()

func get_piece_end(id: int):
	return spawned_pieces[id].get_end()
