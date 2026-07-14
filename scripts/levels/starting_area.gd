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
	
func spawn() -> void:
	return

func configure_spawn(amount: int) -> void: ##Needs to be called by controller second
	return

func populate() -> void: ##Needs to be called by controller first
	return

func get_level_type() -> String:
	if not type:
		printerr("Type not set yet! Maybe be a timing issue!")
	return type

func get_piece_start(id: int) -> void:
	return spawned_pieces[id].get_start()

func get_piece_end(id: int) -> void:
	return spawned_pieces[id].get_end()
