extends Node3D

class_name Ability

@export_group("Required Information")
@export_enum ("Ability", "Upgrade") var type: String

@export_group("Abilities")
@export_enum("timeslow", "boost") var ability_choice: String
@export var intensity: float
@export var duration: float

@export_group("Upgrades")
@export_enum("Max Health", "Regeneration", "Max Stamina","Max Speed", "Jump Quanity", "Jump Height", "Wall Jump Boost Duration", "Wall Jump Speed Boost") var upgrade_choice: String
@export var upgrade_amount: float

var executables: Dictionary

var abilities = ["timeslow", "boost"]
var upgradables = ["Max Health", "Regeneration", "Max Stamina", "Max Speed", "Jump Quanity", "Jump Height", "Wall Jump Boost Duration", "Wall Jump Speed Boost", "Wall Jump Max Speed"]

enum SpeedMod {SPRINT, WALL_JUMP_BOOST, DASH, BOOST}

func _ready() -> void:
	executables = {"timeslow": timeslow, "boost": boost}

func execute(player_node:CharacterBody3D = null):
	if type == "Upgrade":
		print("ABILITY: Type " + type)
		if upgrade_choice not in upgradables:
			printerr("That is not an stat you can upgrade! " + upgrade_choice)
			return
		print("ABILITY: Applying upgrade")
		player_node.upgrade(upgrade_choice, upgrade_amount)

	else:
		print("ABILITY: Executing ability")
		if not executables.has(ability_choice):
			printerr("ABILITY: No existing ability with the name: " + ability_choice)
			return
		executables[ability_choice].call()

func get_upgrades() -> Array:
	return upgradables.duplicate()

func get_abilities() -> Array:
	return abilities.duplicate()

func configure_new_ability(new_type:String):
	type = new_type

func set_ability_options(new_name:String, new_value:float, new_duration:float = 0): ##New Name: A name for the ability\nNew Value: The value for either intensity (for abilities) or upgrade amounts (for upgrades)\nNew Duration: Optional but required for abilities. Auto filled to 0 (
	if type == "Ability":
		ability_choice = new_name
		intensity = new_value
		if new_duration > 0:
			duration = new_duration
		else:
			printerr("ABILITY: Type has been declared as ability. SET THE DURATION PROPERLY")
	else:
		upgrade_choice = new_name
		if upgrade_choice == "Jump Quanity":
			new_value = new_value / 10
			if new_value < 1:
				new_value = 1
		elif upgrade_choice == "Wall Jump Boost Duration":
			new_value = new_value / 10.0
			if new_value < 0.1:
				new_value = 0.1
				
		upgrade_amount = new_value

func timeslow():
	print("ABILITY: Slowing time")
	Engine.time_scale = intensity
	print(Engine.time_scale)
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	print(Engine.time_scale)
	
func boost():
	print("ABILITY: Boosting")
	var player = get_parent()
	player.add_speed_modifier(SpeedMod.BOOST, intensity)
	await get_tree().create_timer(duration).timeout
	player.remove_speed_modifier(SpeedMod.BOOST)
