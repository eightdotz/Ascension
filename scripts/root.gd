extends Node3D

@export var spawn_amount: int = 0 ##The amount of total pieces that can be spawned
@export var room_cooldown: int = 0 ##The amount of connection pieces required before another room can spawn

@export_group("Experimental Settings")
@export var room_cooldown_enable_divide: bool = false ##Instead of the room cooldown variable representing the amount of connection pieces between rooms, it instead specifies the ratio of rooms to Spawn Amount. With this enabled, Room Cooldown being set to 2 means that if Spawn Amount is 10, room cooldown would be Spawn Amount / Room Cooldown or 5
@export var test_load: bool = false ##Enables the default loading of the assigned level
@export var assigned_level: String ##A scene you want to load by default. Needs to comply with level specifications

@onready var level_node: Node3D = $Level
@onready var dungeon: Node3D
@onready var player: CharacterBody3D = $player
@onready var goal: Node3D = $Goal
@onready var ABILITY_SELECTION = "res://scenes/main/AbilitySelection.tscn"

@onready var LEVEL = "res://scenes/main/Level.tscn"
@onready var STARTING = "res://scenes/main/StartingArea.tscn"


var current_floor = -1
signal level_changed

func _ready():
	if not spawn_amount:
		printerr("No spawn amount set! Will crash!")
		return
	if room_cooldown_enable_divide:
		room_cooldown = spawn_amount / room_cooldown
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
	var level_type = dungeon.get_level_type()
	if level_type == "Dungeon":
		dungeon.populate()
		dungeon.configure_spawn(spawn_amount, room_cooldown)
		await dungeon.spawn()
	print(level_type)
	var spawn = dungeon.get_node("SpawnPoint")
	if not spawn:
		printerr("No spawn point!!!")
	set_player()
	set_goal()
	emit_signal("level_changed")
	if level_type == "Dungeon":
		player.fade_to_clear()
	else:
		print("Resetting timers")
		if level_type == "Ability":
			player.set_level("???")
		else:
			player.set_level("Sentenced")
		player.reset_timers()
		player.fade_to_clear(2.0)
		return
	goal.enable()
	current_floor += 1
	player.set_level(str(current_floor))

func load_first_level():
	player.fade_to_black(1.0, true)
	if test_load:
		load_level(assigned_level)
	else:
		load_level(STARTING)

func _on_goal_level_completed() -> void:
	await player.fade_to_black(1.0, true)
	if test_load:
		load_level(assigned_level)
	elif not randi_range(0, 5) and current_floor > 1:
		load_level(ABILITY_SELECTION)
	else:
		load_level(LEVEL)
