extends Node3D


@onready var noise = FastNoiseLite.new()

@export_group("Noise Settings")
@export_enum("Cellular", "Simplex", "Perlin", "Value") var noise_type: String = "Cellular"
@export var resolution: float = 0.1
@export var randomness: float = 10.0
@export var sensitivity: float = -0.92
@export var spawn_limit: int = 6
@export var waittime: float = 7.0
var types = {"Cellular": FastNoiseLite.TYPE_CELLULAR, "Simplex": FastNoiseLite.TYPE_SIMPLEX, "Perlin": FastNoiseLite.TYPE_PERLIN, "Value": FastNoiseLite.TYPE_VALUE}
@onready var timer: Timer = $Timer

@onready var start: Vector3 = $Start.global_position
@onready var y: float = $Start.global_position.y	
@onready var end: Vector3 = $End.global_position
const BUBBLE = preload("uid://bydbt52i4okb5")
var coords = {}
var min_x
var max_x
var min_z
var max_z
var count = 0
func _ready():
	timer.wait_time = waittime
	await get_tree().create_timer(0.3).timeout
	min_x = mini(start.x, end.x)
	max_x = maxi(start.x, end.x)
	min_z = mini(start.z, end.z)
	max_z = maxi(start.z, end.z)
	noise.noise_type = types[noise_type]
	noise.frequency = resolution
	noise.fractal_gain = randomness
	spawn()

func spawn():
	count = 0
	noise.seed = randi()
	for x in range(min_x, max_x + 1):
		for z in range(min_z, max_z + 1):
			if noise.get_noise_2d(x, z) >= sensitivity:
				continue
			coords[count] = [x, y, z]
			count += 1
	count = 0

	for item in coords.keys():
		var choice = randi_range(0, coords.size() - 1)
		var bubble = BUBBLE.instantiate()
		add_child(bubble)
		bubble.global_position = Vector3(coords[choice][0], coords[choice][1], coords[choice][2])
		bubble.start(choice)
		count += 1
		if count > spawn_limit:
			break

func _on_despawn_area_area_entered(area: Area3D) -> void:
	if "Bubble" in area.name:
		area.erase_self()

func _on_timer_timeout():
	spawn()
