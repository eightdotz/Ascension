extends Node3D

@export_enum("Dungeon", "Ability", "Shop") var type: String

func _ready() -> void:
	if not type:
		printerr("Level type not set!")

func get_level_type():
	if not type:
		printerr("Type not set yet! Maybe be a timing issue!")
	return type
