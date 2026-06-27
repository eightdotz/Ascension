extends Node3D

@export var skip_testing: bool = false
@export var test_load: bool = false
@export var assigned_level: String

@onready var level_node: Node3D = $Level
@onready var dungeon: Node3D
@onready var player: CharacterBody3D = $player
@onready var goal: Node3D = $Goal
@onready var ABILITY_SELECTION = "res://scenes/main/AbilitySelection.tscn"

@onready var LEVEL = "res://scenes/main/Level.tscn"


var current_floor = -1
signal level_changed

func _ready() -> void:
	load_first_level()
	set_player()
	set_goal()

func get_level_type():
	if not dungeon:
		return "Dungeon"
	return dungeon.get_level_type()

func set_player():
	var spawn = dungeon.get_node("SpawnPoint")
	if not spawn:
		printerr("No spawn point!!!")
	player.global_position = spawn.global_position
	player.global_rotation = spawn.global_rotation
	player.fade_to_clear()

func set_goal():
	var spawn = dungeon.get_node("GoalPoint")
	if not spawn:
		printerr("No goal spawn point!!!")
		goal.disable()
		return
	goal.global_position = spawn.global_position
	goal.global_rotation = spawn.global_rotation

func load_level(path: String):
	goal.disable()
	for child in level_node.get_children():
		child.queue_free()

	dungeon = load(path).instantiate()
	level_node.add_child(dungeon)
	dungeon.skip_testing = skip_testing
	dungeon.populate()
	dungeon.configure_spawn(10)
	await dungeon.spawn()
	print(dungeon.get_level_type())
	var spawn = dungeon.get_node("SpawnPoint")
	if not spawn:
		printerr("No spawn point!!!")
	player.global_position = spawn.global_position
	player.global_rotation = spawn.global_rotation
	emit_signal("level_changed")
	if dungeon.get_level_type() == "Dungeon":
		player.fade_to_clear()
	else:
		print("Resetting timers")
		player.fade_to_clear(2.0)
		player.set_level("???")
		player.reset_timers()
		return
	goal.enable()
	current_floor += 1
	if current_floor > 0:
		player.set_level(str(current_floor))

func load_first_level():
	player.fade_to_black(1.0, true)
	if test_load:
		load_level(assigned_level)
	else:
		load_level(LEVEL)
		

func _on_goal_level_completed() -> void:
	player.fade_to_black(1.0, true)
	if test_load:
		load_level(assigned_level)
	elif not randi_range(0, 10):
		load_level(ABILITY_SELECTION)
	else:
		load_level(LEVEL)
