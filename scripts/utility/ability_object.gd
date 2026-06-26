extends Node3D
@onready var particles: GPUParticles3D = $Particles
@export var selected_ability: Ability
@export_enum("Common", "Uncommon", "Rare", "Epic", "Legendary") var rarity: String
@export_group("Colors")
@export var white: Color
@export var green: Color
@export var blue: Color
@export var purple: Color
@export var yellow: Color
@export_group("Particle Quantity")
@export var white_amount: int
@export var green_amount: int
@export var blue_amount: int
@export var purple_amount: int
@export var yellow_amount: int
@onready var page_mesh: MeshInstance3D = $Mesh
@onready var input_area: Area3D = $InputArea
var num = 0
signal select
signal unselect
@onready var name_label: Label3D = $Name
@onready var value_label: Label3D = $Value


func _ready() -> void:
	particles.emitting = false
	if rarity:
		set_rarity_properties()

func set_rarity(type: String): ##Configures the look of the item based on rarity and creates ability object
	selected_ability = Ability.new()
	rarity = type
	set_rarity_properties()
	
func set_rarity_properties(): ##Called by 'set_rarity()', configures the look of the item
	var rarity_colors = {"Common": white, "Uncommon": green, "Rare": blue, "Epic": purple, "Legendary": yellow}
	var rarity_amounts = {"Common": white_amount, "Uncommon": green_amount, "Rare": blue_amount, "Epic": purple_amount, "Legendary": yellow_amount}
	particles.amount = rarity_amounts[rarity]
	
	var mesh = particles.draw_pass_1.duplicate()
	particles.draw_pass_1 = mesh
	var mat = mesh.material.duplicate()
	mesh.material = mat
	mat.emission = rarity_colors[rarity]
	
	var new_page_mesh = page_mesh.mesh.duplicate()
	var new_page_material = page_mesh.mesh.material.duplicate()
	page_mesh.mesh = new_page_mesh
	page_mesh.mesh.material = new_page_material
	page_mesh.mesh.material.emission = rarity_colors[rarity]

func start():
	particles.emitting = true

func stop():
	particles.emitting = false

func set_page_value(value: int):
	value_label.text = str(value)
	num = value

func toggle_hitbox():
	input_area.monitoring = !input_area.monitoring
	print(input_area.monitoring)

func set_page_name(new_name:String):
	name_label.text = new_name

func _mouse_entered(area: Area3D) -> void:
	page_mesh.mesh.material.emission_energy_multiplier += 2
	emit_signal("select", num)


func _mouse_left(area: Area3D) -> void:
	page_mesh.mesh.material.emission_energy_multiplier -= 2
	emit_signal("unselect", num)
