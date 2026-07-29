extends Node3D

@export_enum("Dungeon", "Ability", "Shop") var type: String
@export_enum("Sewer", "Fields", "Space","Tower") var biome: String
@onready var main_body: Node3D = $MainBody
@onready var spawn_point: Node3D = $SpawnPoint
@onready var goal_point: Node3D = $GoalPoint
var skip_testing = 1

var get_biome = {"Sewer":"res://game/scenes/biomes/sewer/", "Fields":"res://game/scenes/biomes/fields/", "Space":"res://game/scenes/biomes/space/","Tower":"res://game/scenes/biomes/tower/"}

var spawn_amount: int
var current_id: int = 0
var avaliable_pieces: Array = []
var next_position = Vector3(0,0,0)
var spawned_pieces: Dictionary = {}

func _ready() -> void:
	set_lod(Global.lod_value)
	set_shadow(Global.shadows_enabled)
	set_view(Global.view_distance)
	Global.connect("shadows_toggled", set_shadow)
	Global.connect("lod_changed", set_lod)
	Global.connect("view_distance_changed", set_view)
	if not type:
		printerr("Level type not set!")
	if type == "Dungeon" and not biome:
		printerr("Type is of Dungeon but the Biome has not been defined. This will break!")
	
func spawn() -> void:
	return

func configure_spawn(amount: int) -> int: ##Needs to be called by controller second
	return amount

func populate() -> void: ##Needs to be called by controller first
	return

func get_level_type() -> String:
	if not type:
		printerr("Type not set yet! Maybe be a timing issue!")
	return type

func get_piece_start(id: int):
	return spawned_pieces[id].get_start()

func get_piece_end(id: int):
	return spawned_pieces[id].get_end()

func set_lod(setting: float):
	if not main_body:
		return
	if main_body is MeshInstance3D:
		main_body.lod_bias = setting
	var meshes = main_body.find_children("*", "MeshInstance3D", true, false)
	for item in meshes:
		item.lod_bias = setting

func set_shadow(toggle: bool):
	if not main_body:
		return
	@warning_ignore("int_as_enum_without_cast")
	if main_body is MeshInstance3D:
		main_body.cast_shadow = int(toggle)
	var meshes = main_body.find_children("*", "MeshInstance3D", true, false)
	for item in meshes:
		@warning_ignore("int_as_enum_without_cast")
		item.cast_shadow = int(toggle)
	
func set_view(setting: float):
	if not main_body:
		return
	if main_body is MeshInstance3D:
		main_body.visibility_range_end = setting
	var meshes = main_body.find_children("*", "MeshInstance3D", true, false)
	for item in meshes:
		item.visibility_range_end = setting
