extends Node3D

@export var load_shaders: bool = true ##Whether to load the DisplayAll scene
@export var loading_time: float = 3.0 ##Time for the players loading screen
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

const ABILITY_SELECTION = preload("uid://cgjyggk3k3du3")
const STARTING = preload("uid://bt7lf8ump465u")
const PISS_BREAK = preload("uid://08s4p3p5ek3a")
const LEVEL = preload("uid://bpxtv3md8pmge")
const DISPLAY_SHADERS = preload("uid://28hbku2nok33")
const PLAYER_PATH = preload("uid://bk2r4u7mfbf1b")

var current_biome: String
var on_break: int = 0
var base_spawn
var current_level_type
var current_floor: int = -1
signal level_changed

func _ready() -> void:
	if load_shaders:
		player.load_screen(loading_time)
		var shaders = DISPLAY_SHADERS.instantiate()
		level_node.add_child(shaders)
		var spawn = shaders.get_node("PlayerSpawn")
		player.global_position = spawn.global_position
		player.global_rotation = spawn.global_rotation
		await get_tree().create_timer(loading_time).timeout
		shaders.queue_free()
	
	base_spawn = spawn_amount
	if not spawn_amount:
		printerr("ROOT: No spawn amount set! Will crash!")
		return
	if room_cooldown_enable_divide:
		@warning_ignore("integer_division")
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

func load_level(path: PackedScene) -> void:
	print("LOAD_LEVEL CALLED — stack:")
	for frame in get_stack():
		print("  ", frame)
	for child in level_node.get_children():
		child.queue_free()
	dungeon = path.instantiate()
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
		if dungeon.biome != current_biome:
			print(dungeon.biome + "|" + current_biome)
			dungeon.current_biome = dungeon.biome
			player.set_intro(dungeon.get_intro_title(), dungeon.get_intro_desc())
			#player.toggle_intro()
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
	Global.current_floor += 1
	player.set_level(current_biome, str(Global.current_floor))

func load_first_level() -> void:
		load_level(STARTING)

func _on_goal_level_completed() -> void:
	print("GOAL LEVEL COMPLETED")
	spawn_amount = base_spawn + Global.current_floor
	if Global.current_floor % piss_break_floor == 0 and Global.current_floor != -1 and Global.current_floor and not on_break:
		await player.fade_to_black(0.5, true)
		on_break = true
		load_level(PISS_BREAK)
	elif not randi_range(0, ability_spawn_range) and Global.current_floor > ability_spawn_threshold and current_level_type != "Ability" and current_level_type != "Shop":
		await player.fade_to_black(1.0, true)
		load_level(ABILITY_SELECTION)
		on_break = false
	else:
		await player.fade_to_black(0.5, true)
		load_level(LEVEL)
		if current_level_type == "Dungeon" and Global.current_floor != -1:
			@warning_ignore("narrowing_conversion")
			player.update_coins(randi_range(spawn_amount / 2.0, spawn_amount))
		on_break = false

func reset_floor():
	player.update_coins(-player.coins)
	load_level(LEVEL)

func restart() -> void:
	player.queue_free()
	await get_tree().process_frame
	player = PLAYER_PATH.instantiate()
	$".".add_child(player)
	player.name = "player"
	print(player.name)
	load_first_level()


func _on_killzone_entered(body: Node3D) -> void:
	print("ROOT: Player entered killzone")
	if body.has_method("is_player"):
		await body.handle_death()
		reset_floor()
func disable_goal():
	goal.disable()

func enable_goal():
	goal.enable()
