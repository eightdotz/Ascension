extends Node3D

@export var spawn_amount: int = 0 ##The amount of total pieces that can be spawned
@export var room_cooldown: int = 0 ##The amount of connection pieces required before another room can spawn
@export var ability_spawn_range: int = 1
@export var ability_spawn_threshold: int = 5
@export var piss_break_floor: int = 10
@export_group("Experimental Settings")
@export var room_cooldown_enable_divide: bool = false ##Instead of the room cooldown variable representing the amount of connection pieces between rooms, it instead specifies the ratio of rooms to Spawn Amount. With this enabled, Room Cooldown being set to 2 means that if Spawn Amount is 10, room cooldown would be Spawn Amount / Room Cooldown or 5
@export var test_load: bool = false ##Enables the default loading of the assigned level
@export var assigned_level: String ##A scene you want to load by default. Needs to comply with level specifications

@onready var level_node: Node3D = $Level
@onready var dungeon: Node3D
@onready var player: CharacterBody3D = $player
@onready var goal: Node3D = $Goal
@onready var ABILITY_SELECTION = "res://scenes/main/AbilitySelection.tscn"
@onready var PISS_BREAK = "res://scenes/main/PissBreak.tscn"
@onready var LEVEL = "res://scenes/main/Level.tscn"
@onready var STARTING = "res://scenes/main/StartingArea.tscn"
@onready var player_path = "res://scenes/player/player.tscn"
var current_biome: String
var on_break: int = 0
var base_spawn
var current_level_type
var current_floor: int = -1
signal level_changed

func _ready() -> void:
	base_spawn = spawn_amount
	if not spawn_amount:
		printerr("ROOT: No spawn amount set! Will crash!")
		return
	if room_cooldown_enable_divide:
		room_cooldown = spawn_amount / room_cooldown
	load_first_level()
	set_player()
	set_goal()

func get_level_type() -> String:
	if not dungeon:
		print("No Dungeon")
		return "Dungeon"
	print(dungeon.get_level_type())
	return dungeon.get_level_type()

func set_player() -> void:
	var spawn = dungeon.get_node("SpawnPoint")
	if not spawn:
		printerr("ROOT: No spawn point!!!")
	player.global_position = spawn.global_position
	player.global_rotation = spawn.global_rotation
	player.set_respawn()
	player.fade_to_clear()

func set_goal() -> void:
	var spawn = dungeon.get_node("GoalPoint")
	if not spawn:
		printerr("ROOT: No goal spawn point!!!")
		goal.disable()
		return
	goal.global_position = spawn.global_position
	goal.global_rotation = spawn.global_rotation

func load_level(path: String) -> void:
	goal.disable()
	for child in level_node.get_children():
		child.queue_free()
	dungeon = load(path).instantiate()
	level_node.add_child(dungeon)
	current_level_type = dungeon.get_level_type()
	if current_level_type == "Dungeon":
		dungeon.check_transition(current_floor)
		dungeon.populate()
		dungeon.configure_spawn(spawn_amount, room_cooldown)
		current_biome = dungeon.get_intro_title()
		await dungeon.spawn()
	print(current_level_type)
	var spawn = dungeon.get_node("SpawnPoint")
	if not spawn:
		printerr("ROOT: No spawn point!!!")
	set_player()
	set_goal()
	emit_signal("level_changed")
	if current_level_type == "Dungeon":
		if dungeon.biome != dungeon.current_biome:
			player.set_intro(dungeon.get_intro_title(), dungeon.get_intro_desc())
			#await get_tree().process_frame
			player.toggle_intro()
			dungeon.current_biome = dungeon.biome
			
		player.fade_to_clear(0.2)
	else:
		print("ROOT: Resetting timers")
		if current_level_type == "Ability":
			player.set_level(current_biome, "???")
		else:
			player.set_level(current_biome, "Sentenced")
		player.reset_timers()
		player.fade_to_clear(1.0)
		return
	goal.enable()
	Global.current_floor += 1
	player.set_level(current_biome, str(Global.current_floor))

func load_first_level() -> void:
	if test_load:
		load_level(assigned_level)
	else:
		load_level(STARTING)

func _on_goal_level_completed() -> void:
	print(base_spawn)
	spawn_amount = base_spawn + Global.current_floor
	print(spawn_amount)
	if test_load:
		load_level(assigned_level)
		return
	if Global.current_floor % piss_break_floor == 0 and Global.current_floor != -1 and Global.current_floor and not on_break:
		await player.fade_to_black(0.5, true)
		on_break = true
		load_level(PISS_BREAK)
	elif not randi_range(0, ability_spawn_range) and Global.current_floor > ability_spawn_threshold and current_level_type != "Ability":
		await player.fade_to_black(1.0, true)
		load_level(ABILITY_SELECTION)
		on_break = false
	else:
		await player.fade_to_black(0.5, true)
		load_level(LEVEL)
		if current_level_type == "Dungeon" and Global.current_floor != -1:
			player.update_coins(randi_range(spawn_amount / 2, spawn_amount))
		on_break = false

func reset_floor():
	player.update_coins(-player.coins)
	load_level(LEVEL)

func restart() -> void:
	player.queue_free()
	await get_tree().process_frame
	player = load(player_path).instantiate()
	$".".add_child(player)
	player.name = "player"
	print(player.name)
	load_first_level()
	
