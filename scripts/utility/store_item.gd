extends Area3D
@export var mesh: MeshInstance3D
@export var item: Item
var item_image_path = "res://images/items/"

func _ready() -> void:
	mesh = get_parent()

func set_item(new_item: Item):
	item = new_item
	var dir := DirAccess.open(item_image_path)
	if dir == null: printerr("LEVEL GENERATION: Could not open folder"); return
	dir.list_dir_begin()
	for file: String in dir.get_files():
		if item.item_type in file:
			var image = load(file)
			mesh.set_surface_override_material(0 ,image) #change to set real material
			#so you can turn on billboard
