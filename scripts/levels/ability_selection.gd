extends Node3D
@export_enum("Dungeon", "Ability", "Shop") var level_type: String
var type
@export var cursor: GPUParticles3D
@onready var player = get_parent().get_parent().get_node("player")
@onready var ability: Node3D = $Abilities/Ability
@onready var ability_2: Node3D = $Abilities/Ability2
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var root = get_parent().get_parent()
var on_card = false
var selected_card = 0
var viewing = false

var value = 0
signal level_completed

func _ready():
	randomize_ability()
	set_physics_process(false)
	cursor.visible = false
	player.disable_mouse()
	player.disable_movement()
	level_completed.connect(root._on_goal_level_completed)
	call_deferred("_intro")
	
func random(list:Array):
	return list[randi() % list.size()]

func random_type():
	if randi() % 20 > 18:
		return "Ability"
	else:
		return "Upgrade"

func random_rarity():
	var num = randi() % 100
	var rarity
	if num > 96:
		rarity = "Legendary"
	elif num > 85 and num <= 96:
		rarity = "Epic"
	elif num > 70 and num <= 85:
		rarity = "Rare"
	elif num > 45 and num <= 70:
		rarity = "Uncommon"
	elif num <= 45:
		rarity = "Common"
	else:
		rarity = "Common"
	return rarity

func random_value(rarity: String, current_type:String):
	if current_type == "Upgrade":
		var common: float = (randi_range(10, 50) / 10.0)
		var uncommon: float = (randi_range(15, 70) / 10.0)
		var rare: float = (randi_range(25, 100) / 10.0)
		var epic: float = (randi_range(45, 140) / 10.0)
		var legendary: float = (randi_range(70, 200) / 10.0)

		if rarity == "Legendary":
			return legendary + (randi_range(25, 40) / 10.0)
		elif rarity == "Epic":
			return epic + (randi_range(15, 30) / 10.0)
		elif rarity == "Rare":
			return rare + (randi_range(10, 25) / 10.0)
		elif rarity == "Uncommon":
			return uncommon + (randi_range(5, 15) / 10.0)
		else:
			return common + (randi_range(1, 10) / 10.0)
	return 0
func randomize_ability():
	var rarity = random_rarity()
	ability.set_rarity(rarity)
	
	var upgrade_options = ability.selected_ability.get_upgrades()
	var abilities = ability.selected_ability.get_abilities()
	var current_type = random_type()
	
	ability.selected_ability.configure_new_ability(current_type)
	value = random_value(rarity, current_type)
	print(value)
	if current_type == "Ability":
		var new_ability = random(abilities)
		if new_ability == "timeslow":
			value = randi_range(10, 80) / 100.0
			print(value)
		ability.selected_ability.set_ability_options(new_ability, value, (randi_range(100, 500) / 100.0))
		ability.set_page_name(new_ability)
	else:
		var upgrade_option = random(upgrade_options)
		ability.set_page_name(upgrade_option)
		ability.selected_ability.set_ability_options(upgrade_option, value)
	ability.set_page_value(1)
	rarity = random_rarity()
	type = random_type()
	value = random_value(rarity, type)
	ability_2.set_rarity(rarity)
	ability_2.selected_ability.configure_new_ability(type)
	print(value)
	if current_type == "Ability":
		var new_ability = random(abilities)
		if new_ability == "timeslow":
			value = randi_range(10, 80) / 100.0
			print(value)
		ability_2.selected_ability.set_ability_options(new_ability, value, (randi_range(100, 500) / 100.0))
		ability_2.set_page_name(new_ability)
	else:
		var upgrade_option = random(upgrade_options)
		ability_2.set_page_name(upgrade_option)
		ability_2.selected_ability.set_ability_options(random(upgrade_options), value)
	ability_2.set_page_value(2)

func _intro():
	animation_player.play("Fall")
	await player.fade_to_clear(1.5, true)
	ability.start()
	ability_2.start()
	set_physics_process(true)
	cursor.visible = true
	player.toggle_mouse()
	player.enable_mouse()

func _physics_process(_delta: float) -> void:
	
	var cam := player.get_child(0).get_child(0) #Gets camera object
	var mouse = player.get_mouse()
	var ray_start: Vector3 = cam.project_ray_origin(mouse)
	var direction: Vector3 = cam.project_ray_normal(mouse)
	var space_state := get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(ray_start, ray_start + direction * 10.0)
	ray.collision_mask = 1
	var result := space_state.intersect_ray(ray)
	
	if result:
		cursor.position = result.position

func toggle_card():
	if animation_player.is_playing(): return
	print(viewing, on_card, selected_card)
	ability_2.toggle_hitbox()
	ability.toggle_hitbox()
	if not viewing:
		viewing = true
		animation_player.play("View_" + str(selected_card))
		await animation_player.animation_finished
	else:
		viewing = false
		animation_player.play("Return_" + str(selected_card))
		await animation_player.animation_finished

func select_card():
	if selected_card == 1:
		player.add_ability(ability.selected_ability)
	else:
		player.add_ability(ability_2.selected_ability)
	animation_player.play("Accept_" + str(selected_card))
	await animation_player.animation_finished
	set_physics_process(true)
	player.enable_movement()
	player.enable_mouse()
	player.toggle_mouse()
	emit_signal("level_completed")
	#level_completed.disconnect(root._on_goal_level_completed)
	
func _on_ability_select(new_value: int) -> void:
	on_card = true
	selected_card = new_value

func _on_ability_unselect(new_value: int) -> void:
	if not viewing:
		on_card = false
		selected_card = new_value

func _on_click(button: int) -> void:
	if not on_card and not viewing:
		return
	if button == MOUSE_BUTTON_LEFT:
		if not viewing:
			toggle_card()
		else:
			select_card()
	elif button == MOUSE_BUTTON_RIGHT:
		toggle_card()

func get_level_type():
	if not level_type:
		printerr("Type not set yet! Maybe be a timing issue!")
	return level_type
