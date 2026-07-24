extends Node3D
@onready var item_1: Area3D = $Item1
@onready var item_2: Area3D = $Item2
@onready var item_3: Area3D = $Item3

var items = [item_1, item_2,  item_3]
func _ready() -> void:
	print("STORE: Preparing store")


func assign_item():
	for item in items:
		item.populate()
