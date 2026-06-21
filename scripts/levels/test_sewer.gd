extends Node3D

@export var randomize_traps: bool = false ##When using multiple traps, this randomizes them
@export var traps: Array[NodePath] = [] ##Assign the paths to traps here

func _ready():
	if randomize_traps:
		randomize_trap()

func turn_off_traps():
	for i in traps:
		var temp = get_node(i)
		temp.visible = false
		

func randomize_trap():
	turn_off_traps()
	print("Randomized traps ARE enabled, ensure this is intentional. Any trap assigned will be set to invisible.")
	var name = traps[randi_range(0, traps.size() - 1)]
	print("Selected:")
	print(name)
	var trap = get_node(name)
	if not trap:
		printerr("Trap not found! You have an invalid path inside of your trap randomization!")
	trap.visible = true

#func _player_entered_water(body: Node3D) -> void:
#	if body.has_method("is_player"):
#		body.in_water = true
#		print("Player entered water.")


#func _player_exited_water(body: Node3D) -> void:
#	if body.has_method("is_player"):
#		body.in_water = false
#		print("Player left water.")
