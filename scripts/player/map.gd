extends MeshInstance3D
@onready var player: CharacterBody3D = $"../.."
@onready var timer: Timer = $Timer
@onready var health_indicator = $Health.get_active_material(0) as StandardMaterial3D
@onready var infection_indicator = $Infection.get_active_material(0) as StandardMaterial3D



func _on_player_health_changed(val: float) -> void:
	health_indicator.emission = Color(player.health / 100, 0, 0, 1)


func _on_timer_timeout() -> void:
	infection_indicator.emission = Color(0, player.current_infection / 100, 0, 1)

func set_level(biome: String, value: String):
	var title = $Screen/Biome
	var floor = $Screen/Floor
	title.text = biome
	floor.text = value
