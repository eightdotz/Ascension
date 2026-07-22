extends CharacterBody3D

@export var diagnostics_enabled: bool = false
@onready var root: Node3D = get_parent() 
@export var enable_flashlight:bool = false

@export_group("Infection")
@export var infection_limit: float
@export var infection_rate: float
@export var infection_reduction: float
@export var infection_increase: float
@export_group("Abilities")
@export var ability_1: Ability
@export var ability_2: Ability
@export var ability_3: Ability

@export_group("Health")
@export var health: float = 100.0 ##Player starting health
@export var health_max: float = 100.0 ##The maximum health that the player can heal to
@export var regen: float = 0.1 ##Amount of health regenerated per delta
@export var invincibility_duration: float = 0.5 ##Duration in seconds of invulnerability after being hit

@export_group("Stamina")
@export var stamina: float = 100.0 ##Player starting stamina
@export var stamina_max: float = 100.0 ##Maximum stamina that can be regenerated
@export var stamina_build_passive: float = 40.0 ##Amount of stamina build passively * delta
@export var stamina_drain_sprint: float = 1.0 ##Stamina drain from sprinting * delta
@export var stamina_drain_jump: float = 0.5 ##Stamina drain from jumping 

@export_group("Speed")
@export var max_speed: float = 30.0 ##Max speed with no modifiers or sprint
@export var air_speed: float = 1.5 ##The amount of control while in air
@export var fall_speed: float = 5.0 ##The speed at which the player decends while holding ctrl
@export var accel: float = 700.0 ##Acceleration from stop
@export var decel: float = 0.3 ##Decceleration from current velocity
@export var gravity: float = 50.0 ##You know what this means
@export var jump_speed: float = 50.0 ##Speed at which the player departs from surface

@export_group("Jump")
@export var jump_max := 3 ##Amount of jumps avaliable
@export var jump_cooldown: float = 0.2 ##Length in seconds between jumps to prevent spamming
@export var jump_max_held: float = 0.2 ##Allows for higher jumps when pressed longer

@export_group("Settings")
@export var mouse_sensitivity: float = 0.1 ##Sensitivity

@export_group("Wall Jump")
@export var wall_jump_force: float = 140.0 ##Speed of a jump when departing from a wall
@export var wall_jump_force_init: float = 125.0 ##The initial speed burst when performing a wall jump
@export var wall_angle: float = 5.0 ##Minimum angle for walls to be jumped off of
@export var max_wall_angle: float = 150.0 ##Maximum angle for walls to be jumped off of
@export var straight_wall_leeway: int = 3 ##The amount of range to or from 90 degrees that is accepted as a "straight wall" or surface that cannot be jumped off of
@export var wall_jump_velocity_preserve_time: float = 0.2 ##Amount of time top speed is preserved
@export var wall_jump_velocity_max: float = 120.0 ##Maximum speed with any boost
@export var wall_jump_speed_boost: float = 1.2 ##Amount added to maximum speed after wall jump
@export var wall_jump_boost_duration: float = 3.5 ##Amount of time added to boost duration

@export_group("FOV")
@export var base_fov: float = 75.0 ##Default field of view
@export var sprint_fov_boost: float = 5.0 ##The amount field of view increases while sprinting
@export var wall_jump_fov_boost: float = 25.0 ##The amount field of view can increase during a wall jump or max speed
@export var fov_lerp_speed: float = 8.0 ##The speed at which the field of view changes

@export_group("Shader")
@export_range (0.0, 100.0, 0.1) var pixelization: float
@onready var shader_mesh: ColorRect = $Interface/HUD/PixelFilter

@export_group("Misc")
@export var knockback_decay: float = 4.0
@export var coins: float = 0.0

@onready var cache_max_speed := max_speed
@onready var player_head = $Head
@onready var camera = $Head/Camera
@onready var interact: RayCast3D = $Head/Interact

enum SpeedMod {SPRINT, WALL_JUMP_BOOST, BOOST, SLOW}
var _speed_modifiers: Dictionary = {}

var movement_override_timer: float = 0.0 #while > 0, the normal speed clamp/accel is skipped. Used by wall jump and dash.

var wall_stick_timer: float = 0.0
var jump_time: float = 0.0
var last_gnd_time: float = 0.0
var last_jump_time: float = 0.0

var tilt_amount: float = 0.1
var rotation_x: float = 0.0

var mouse_captured: float = true
var direction := Vector3.ZERO
var wall_normal := Vector3.ZERO
var jumps: int = 0
var is_jumping: bool = false
var is_sliding: bool = false
var just_wall_jumped: bool = false

var wall_slide_speed: float = 10.0
var wall_stick_duration: float = 0.3
var wall_stick_velocity_threshold: float = 5.0
var infection_speed_relief : float = wall_jump_velocity_max
var wall_jump_boost_timer: float = 0.0
var wall_jump_timer: float = 0.0
var is_invincible: float = false
var invincibility_timer: float = 0.0
var current_infection: float = 0.0
var infecting: bool = false

var cos_wall_angle_min: float
var cos_wall_angle_max: float
var cos_straight_min: float
var cos_straight_max: float

var knockback_velocity: Vector3
var knockback_dir: Vector3
var being_knocked_back: int = 0
var tween = null

var wall_jump_boost_timer_max: float = (wall_jump_velocity_max / 10.0) + 3
#Performance shiz
@onready var wall_rays = $WallCast.get_children() #so we dont use get_children every loop
@onready var gnd_ray = $GNDRayCast
@onready var diagnostics: Control = $Interface/Diagnostics
@onready var label_current_speed: Label = $Interface/Diagnostics/CurrentSpeed
@onready var label_boost_duration: Label = $Interface/Diagnostics/BoostDuration
@onready var label_sliding: Label = $Interface/Diagnostics/Sliding
@onready var label_wall_angle: Label = $Interface/Diagnostics/WallAngle
@onready var label_mv_override: Label = $Interface/Diagnostics/MvOverride
@onready var label_max_speed: Label = $Interface/Diagnostics/MaxSpeed
@onready var label_fov: Label = $Interface/Diagnostics/FOV
@onready var label_direction: Label = $Interface/Diagnostics/Direction

#@onready var bar_health: ProgressBar = $Interface/HUD/Health
#@onready var bar_stamina: ProgressBar = $Interface/HUD/Stamina
#@onready var bar_jumps: ProgressBar = $Interface/HUD/Jumps
@onready var black_screen: ColorRect = $Interface/HUD/BlackScreen
@onready var hud: Control = $Interface/HUD
@onready var level: Label = $Interface/HUD/Level
@onready var pause: Control = $Interface/Pause
@onready var main_menu: Control = $Interface/MainMenu
@onready var damage_filter: ColorRect = $Interface/HUD/DamageFilter
@onready var interface: Control = $Interface
@onready var menu_music_player: AudioStreamPlayer = $AFX/MenuMusicPlayer
@onready var level_ambience: AudioStreamPlayer = $AFX/LevelAmbience
@onready var level_music: AudioStreamPlayer = $AFX/LevelMusic
@onready var sfx_player: AudioStreamPlayer = $AFX/SFX
@onready var all_audio = $AFX.get_children()
#@onready var infection: ProgressBar = $Interface/HUD/Infection
@onready var flashlight: SpotLight3D = $Head/Flashlight
@onready var animation_player: AnimationPlayer = $Head/AnimationPlayer

@onready var health_bar: MeshInstance3D = $Head/Map/Health
@onready var stamina_bar: MeshInstance3D = $Head/Map/Stamina
@onready var infection_bar: MeshInstance3D = $Head/Map/Infection

var is_terminal_shown = false
var respawn_pos: Vector3
var respawn_rot: Vector3
var current_ambience: String = ""
var walking_sounds: Array = []

#mouse signals
signal on_click

#stat signals
signal health_changed(val: float)
signal coins_changed(val: float)
@onready var loading_screen: Control = $LoadingScreen

func _ready() -> void:
	loading_screen.visible = false
	infection_speed_relief = wall_jump_velocity_max
	wall_jump_boost_timer_max = (wall_jump_velocity_max / 10.0) + 3
	Global.connect("gravity_changed", set_gravity)
	if not root:
		print("PLAYER: (ready) Getting root")
		root = get_parent()
	if root:
		print("PLAYER: Connecting level change signal")
		root.connect("level_changed", _on_root_level_changed)
	if enable_flashlight:
		flashlight.visible = true
	else:
		flashlight.visible = false
	cos_wall_angle_min = cos(deg_to_rad(wall_angle))
	cos_wall_angle_max = cos(deg_to_rad(max_wall_angle))
	cos_straight_min = cos(deg_to_rad(90 - straight_wall_leeway))
	cos_straight_max = cos(deg_to_rad(90 + straight_wall_leeway))
	#load_sounds()
	camera.global_rotation.x -= 50
	menu_play("res://audio/music/gamemaintheme_rev_2.ogg")
	if diagnostics_enabled:
		diagnostics.visible = true
	else:
		diagnostics.visible = false
	jumps = jump_max
	#bar_jumps.value = jump_max
	gnd_ray.target_position = Vector3(0, -1.1, 0)
	gnd_ray.enabled = true
	add_to_group("player")
	if camera:
		camera.fov = base_fov
	pause_effect()
	toggle_mouse()
	set_process_input(!is_processing_input())
	set_physics_process(!is_physics_processing())

func _input(event) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		rotation_x = clamp(rotation_x - event.relative.y * mouse_sensitivity, -90, 90)
		player_head.rotation.x = deg_to_rad(rotation_x)
	else:
		if event is InputEventMouseButton:
			if event.button_index and event.is_pressed():
				_on_click(event.button_index)
				interact_with(event.button_index)
		if Input.is_action_just_pressed("move_pause"):
			if not is_processing_unhandled_input():
				_on_menu_button_pressed_ability()

func _unhandled_input(_event) -> void:
	if Input.is_action_just_pressed("move_pause"):
		_on_menu_button_pressed()
	if Input.is_action_just_pressed("show_term"):
		if is_terminal_shown:
			animation_player.play("hide_terminal")
			is_terminal_shown = false
		else:
			animation_player.play("show_terminal")
			is_terminal_shown = true
		
	if Input.is_action_just_pressed("ability_1"):
		if ability_1:
			ability_1.execute()
	elif Input.is_action_just_pressed("ability_2"):
		if ability_2:
			ability_2.execute()
	elif Input.is_action_just_pressed("ability_3"):
		if ability_3:
			ability_3.execute()

func add_speed_modifier(id: SpeedMod, multiplier: float, duration: float = -1.0) -> void:
	_speed_modifiers[id] = {"mult": multiplier, "timer": duration}

func remove_speed_modifier(id: SpeedMod) -> void:
	_speed_modifiers.erase(id)

func _update_speed_modifiers(delta: float) -> void:
	for id in _speed_modifiers.keys():
		var mod = _speed_modifiers[id]
		if mod.timer >= 0.0:
			mod.timer -= delta
			if mod.timer <= 0.0:
				_speed_modifiers.erase(id)

func get_effective_max_speed() -> float:
	var result = cache_max_speed
	for mod in _speed_modifiers.values():
		result *= mod.mult
	return result

func _update_sprint_modifier(delta: float) -> void:
	if Input.is_action_pressed("move_sprint") and stamina > stamina_drain_sprint:
		add_speed_modifier(SpeedMod.SPRINT, 2.0)
		stamina = max(stamina - stamina_drain_sprint * delta, 0.0)
	else:
		remove_speed_modifier(SpeedMod.SPRINT)

func _update_wall_jump_boost(delta: float) -> void:
	if wall_jump_boost_timer <= 0.0:
		remove_speed_modifier(SpeedMod.WALL_JUMP_BOOST)
		return
	wall_jump_boost_timer -= delta
	var time_progress = 1.0 - (wall_jump_boost_timer / wall_jump_boost_duration)
	var drag_factor = max(0.1, 0.6 - (time_progress * 0.5))
	var boosted_speed = cache_max_speed * wall_jump_speed_boost * drag_factor
	var speed_limit = (wall_jump_velocity_max / 2.0)
	var clamped_speed = max(cache_max_speed, min(boosted_speed, speed_limit))
	add_speed_modifier(SpeedMod.WALL_JUMP_BOOST, clamped_speed / cache_max_speed)



func _process(delta) -> void:
	update_camera_fov(delta)
	update_stamina_and_timers(delta)

func _physics_process(delta) -> void:
	last_gnd_time += delta
	last_jump_time += delta
	
	_update_sprint_modifier(delta)
	_update_wall_jump_boost(delta)
	_update_speed_modifiers(delta)
	max_speed = get_effective_max_speed()

	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	direction = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
		is_sliding = false
	else:
		update_wall_status(direction)
	
	if is_sliding and wall_normal != Vector3.ZERO:
		var right_vector = transform.basis.x.normalized()
		
		var tilt_amount_target = 0.0
		if right_vector.dot(wall_normal) > 0:
			tilt_amount_target = -0.3
		else:
			tilt_amount_target = 0.3
		
		rotation.z = lerp(rotation.z, tilt_amount_target, 8 * delta)
	else:
		rotation.z = lerp(rotation.z, 0.0, 5 * delta)
	
	var grounded = is_on_floor() or gnd_ray.is_colliding()
	
	if grounded:
		last_gnd_time = 0.0
		jumps = jump_max
		is_sliding = false
	else:
		velocity.y -= gravity * delta
	
	handle_jump_buffer(delta, grounded)
	if is_jumping:
		jump_time += delta
		if not Input.is_action_pressed("move_jump") or jump_time >= jump_max_held:
			is_jumping = false
			if velocity.y > 0:
				velocity.y *= 0.5
	
	if not grounded and Input.is_action_pressed("move_fall"):
		velocity.y -= gravity * delta * fall_speed
	
	if not grounded and direction == Vector3.ZERO:
		velocity.x *= 0.98
		velocity.z *= 0.98

	var horiz = Vector2(velocity.x, velocity.z)
	var max_horiz_speed = max_speed
	if movement_override_timer > 0:
		movement_override_timer -= delta
	else:
		if horiz.length() > max_horiz_speed:
			horiz = horiz.normalized() * max_horiz_speed
			velocity.x = horiz.x
			velocity.z = horiz.y
		just_wall_jumped = false
		handle_move(delta, grounded)
		
	if diagnostics_enabled:
		label_mv_override.text = "Engine Time: " + str(Engine.time_scale)
		label_current_speed.text = "Current Speed: " + str(max_horiz_speed)
		label_sliding.text = "Is Character Sliding: " + str(is_sliding)
		label_boost_duration.text = str(wall_jump_boost_timer)
		label_fov.text = "Field of View: " + str(camera.fov)
		label_direction.text = "FPS: " + str(Engine.get_frames_per_second())
		
	if being_knocked_back:
		apply_knockback(delta)
	move_and_slide()
	
func update_stamina_and_timers(delta) -> void:
	if not Input.is_action_pressed("move_sprint"):
		stamina += stamina_build_passive * delta
		stamina = min(stamina, stamina_max)
	
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false

	
	if current_infection <= infection_limit:
		if infecting:
			var relief_percent = clamp(get_effective_max_speed() / infection_speed_relief, 0.0, 1.0)
			current_infection += infection_rate * (1.0 - relief_percent) * delta
	else:
		current_infection = 0.0
		handle_death()

func update_camera_fov(delta) -> void:
	if not camera or stamina < stamina_drain_sprint:
		return
	
	var target_fov = base_fov
	
	if Input.is_action_pressed("move_sprint"):
		target_fov += sprint_fov_boost
	if wall_jump_boost_timer > 0:
		var boost_ratio = wall_jump_boost_timer / wall_jump_boost_duration
		target_fov += wall_jump_fov_boost * boost_ratio
	
	target_fov = clamp(target_fov, base_fov, base_fov + sprint_fov_boost + wall_jump_fov_boost)
	camera.fov = lerp(camera.fov, target_fov, fov_lerp_speed * delta)
func get_body_center() -> Vector3:
	return global_position + Vector3(0, -0.8, 0)

func handle_move(delta: float, grounded: bool) -> void:
	var control_force = 1.0 if grounded else air_speed
	if direction != Vector3.ZERO:
		var target_vel = direction * max_speed
		velocity.x = move_toward(velocity.x, target_vel.x, accel * delta * control_force)
		velocity.z = move_toward(velocity.z, target_vel.z, accel * delta * control_force)
	else:
		var damp = decel * control_force
		velocity.x *= damp
		velocity.z *= damp

func handle_jump_buffer(_delta: float, grounded: bool) -> void:
	if Input.is_action_just_pressed("move_jump"):
		if last_jump_time > jump_cooldown:
			if is_sliding and jumps > 0:
				do_wall_jump()
			elif jumps > 0 and grounded:
				do_jump(Vector3.UP)
			elif jumps > 0:
				do_jump(Vector3.UP)

func do_jump(new_direction: Vector3) -> void:
	if stamina < stamina_drain_jump:
		return
	is_jumping = true
	stamina -= stamina_drain_jump
	stamina = max(stamina, 0.0)
	jump_time = 0.0
	jumps -= 1
	#bar_jumps.value = jumps
	last_jump_time = 0.0
	velocity.y = new_direction.y * jump_speed

func do_wall_jump() -> void:
	if stamina < stamina_drain_jump:
		return
	stamina -= stamina_drain_jump
	stamina = max(stamina, 0.0)

	var camera_forward = -camera.global_transform.basis.z.normalized() 
	camera_forward.y *= 0.9
	camera_forward = camera_forward.normalized()
	
	var wall_jump_velocity = camera_forward * wall_jump_force
	
	if wall_jump_velocity.length() > wall_jump_force:
		wall_jump_velocity = wall_jump_velocity.normalized() * (wall_jump_force)
	
	velocity = wall_jump_velocity
	
	var max_wall_jump_speed = wall_jump_velocity_max
	if velocity.length() > max_wall_jump_speed:
		velocity = velocity.normalized() * (max_wall_jump_speed)
	
	is_sliding = false
	is_jumping = true
	jump_time = 0.0
	jumps -= 1
	#bar_jumps.value = jumps
	last_jump_time = 0.0
	wall_jump_timer += jump_cooldown
	just_wall_jumped = true
	movement_override_timer = wall_jump_velocity_preserve_time
	if wall_jump_boost_timer < wall_jump_boost_timer_max:
		wall_jump_boost_timer += wall_jump_boost_duration

func update_wall_status(input_dir) -> void:
	if is_on_floor():
		is_sliding = false
		wall_normal = Vector3.ZERO
		wall_stick_timer = 0.0
		return
		
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var has_input = input.length() > 0.001
	
	var found_wall = false
	for ray in wall_rays:
		if ray.is_colliding():
			var normal = ray.get_collision_normal()
			var angle_dot = normal.dot(Vector3.UP)
			if angle_dot > cos_straight_max and angle_dot < cos_straight_min:
				continue
			if angle_dot > cos_wall_angle_max and angle_dot < cos_wall_angle_min:
				var to_wall = -normal.normalized()
				var dot = input_dir.dot(to_wall)
				var toward_wall = has_input and dot > 0.1
				if toward_wall or (is_sliding and wall_normal.dot(normal) > 0.7):
					wall_normal = normal
					

					found_wall = true
					break
	if found_wall and not is_on_floor() and last_gnd_time > 0.1:
		if not is_sliding:
			wall_stick_timer = wall_stick_duration
			jumps = jump_max
			#bar_jumps.value = jumps
		
		wall_normal = wall_normal.normalized()
		is_sliding = true
		
		if wall_stick_timer > 0.0:
			wall_stick_timer -= get_physics_process_delta_time()
			var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
			var wall_direction = -wall_normal
			wall_direction.y = 0
			wall_direction = wall_direction.normalized()
			
			var vel_toward_wall = horizontal_vel.dot(wall_direction)
			if vel_toward_wall > 0:
				horizontal_vel -= wall_direction * min(vel_toward_wall, wall_stick_velocity_threshold)
			
			velocity.x = horizontal_vel.x
			velocity.z = horizontal_vel.z
			
			if velocity.y < 0:
				velocity.y = max(velocity.y, -wall_slide_speed)
	else:
		is_sliding = false
		wall_normal = Vector3.ZERO
		wall_stick_timer = 0.0

func take_damage(damage: float) -> float:
	if is_invincible or health <= 0:
		return 0.0
	
	var damage_dealt = min(damage, health)
	health -= damage_dealt
	health_changed.emit(health)
	is_invincible = true
	invincibility_timer = invincibility_duration
	flash_screen_red()
	
	if health <= 0:
		handle_death()
	
	return damage_dealt

func flash_screen_red() -> void:
	apply_damage_filter()
	await get_tree().create_timer(0.2).timeout
	remove_damage_filter()

func handle_death() -> void:
	if current_infection < infection_limit:
		await fade_to_black(1.0, true)
		respawn_player()
		return
	toggle_mouse()
	disable_movement()
	var death_interface = $Interface/Death
	var label: Label = $Interface/Death/Label
	death_interface.visible = true
	tween = create_tween()
	fade_to_black(1.0)
	tween.tween_property(label, "theme_override_colors/font_color:a", 1.0, 2.0)
	await tween.finished
	for item in death_interface.get_children():
		item.visible = true
	
func respawn_player() -> void:
	health = health_max
	health_changed.emit(health)
	current_infection = current_infection * infection_increase
	root.reset_floor()
	self.global_position = respawn_pos
	self.global_rotation = respawn_rot

func is_player() -> int:
	return 1

#HUD
func toggle_mouse() -> void:
	mouse_captured = !mouse_captured
	var mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE
	Input.warp_mouse((hud.get_viewport_rect().size / 2.0))
	Input.set_mouse_mode(mode)

func disable_mouse() -> void:
	set_process_input(false)

func enable_mouse() -> void:
	set_process_input(true)

func disable_movement() -> void:
	set_physics_process(false)
	set_process_unhandled_input(false)
	
func enable_movement() -> void:
	set_physics_process(true)
	set_process_unhandled_input(true)
	
func fade_to_black(time: float = 0.5, wait:bool = false) -> void:
	black_screen.color.a = 0.0
	tween = create_tween()
	tween.tween_property(black_screen, "color:a", 1.0, time)
	if wait:
		await tween.finished

func fade_to_clear(time: float = 0.5, wait:bool = false) -> void:
	black_screen.color.a = 1.0
	tween = create_tween()
	tween.tween_property(black_screen, "color:a", 0.0, time)
	if wait:
		await tween.finished

func get_mouse() -> Vector2:
	return get_viewport().get_mouse_position()

func _on_click(button: int) -> void:
	emit_signal("on_click", button)
	
func upgrade(upgrade_name: String, amount: float) -> void:
	match upgrade_name:
		"Max Health":
			health_max += amount
		"Regeneration":
			regen += amount
		"Base Speed":
			max_speed = cache_max_speed
			max_speed += amount
			cache_max_speed = max_speed
		"Jump Quanity":
			if amount < 1.0:
				amount = 1
			else:
				amount = int(amount)
			@warning_ignore("narrowing_conversion")
			jump_max += amount
		"Jump Height":
			jump_speed += amount
		"Boost Duration":
			wall_jump_boost_duration += amount
		"Wall Jump Force":
			wall_jump_force += amount
		"True Max Speed":
			wall_jump_velocity_max += amount

	infection_speed_relief = wall_jump_velocity_max

func add_ability(new_ability: Ability) -> void:
	if new_ability.type == "Upgrade":
		print("PLAYER:\nUpgrading")
		new_ability.execute(self)
		return
	print("PLAYER:\nAssigning")
	if not ability_1:
		ability_1 = new_ability
	elif not ability_2:
		ability_2 = new_ability
	elif not ability_3:
		ability_3 = new_ability
	else:
		overwrite_ability(new_ability)

@warning_ignore("unused_parameter")
func overwrite_ability(new_ability: Ability) -> void:
	pass

func _on_root_level_changed() -> void:
	print("PLAYER: Level Changed")
	await get_tree().process_frame
	if not root:
		root = get_parent()
	if root:
		print("PLAYER: Found Root")
		infecting = true
		if current_infection:
			current_infection -= (current_infection / infection_reduction)
		if root.get_level_type() == "Ability":
			infecting = false
			print("PLAYER: Level Type is ability")
			var dungeon = root.dungeon
			if dungeon:
				if on_click.is_connected(dungeon._on_click):
					on_click.disconnect(dungeon._on_click)
				on_click.connect(dungeon._on_click)
		elif root.get_level_type() == "Shop":
			infecting = false
	else:
		print("PLAYER: ROOT NOT LOCATED!!")
	var material := shader_mesh.get_material() as ShaderMaterial

	material.set_shader_parameter("flash_amount", 0.0)
	material.set_shader_parameter("flash_pivot", 0.5)
	material.set_shader_parameter("flash_softness", 0.05)
	material.set_shader_parameter("pixel_size", pixelization)
	material.set_shader_parameter("shadow_crush", 0.0)
	material.set_shader_parameter("highlight_boost", 0.0)
	remove_speed_modifier(SpeedMod.SLOW)

func set_level(biome: String, value: String) -> void:
	var map = $Head/Map
	map.set_level(biome, value)

func get_level() -> String:
	return level.text

func reset_timers() -> void:
	wall_jump_boost_timer = 0.0
	movement_override_timer = 0.0
	wall_jump_timer = 0.0

func _on_menu_button_pressed_ability() -> void:
	pause.visible = !pause.visible
	Global.pause_sound.emit()
	if pause.visible:
		pause_effect()
	else:
		unpause_effect()


func _on_menu_button_pressed() -> void:
	if not is_processing_unhandled_input():
		_on_menu_button_pressed_ability()
		return
	if main_menu.visible:
		_start_game()
		return
	set_process_input(!is_processing_input())
	set_physics_process(!is_physics_processing())
	pause.visible = !pause.visible
	toggle_mouse()
	Global.pause_sound.emit()
	if pause.visible:
		infecting = false
		pause_effect()
		
	else:
		infecting = true
		unpause_effect()


func _start_game() -> void:
	main_menu.visible = !main_menu.visible
	toggle_mouse()
	set_process_input(!is_processing_input())
	set_physics_process(!is_physics_processing())
	unpause_effect()
	tween = create_tween()
	menu_stop()
	start_ambience("res://audio/ambience/StartingAreaWhiteNoise.ogg", "res://audio/music/StartingAreaSong1.ogg")

func _on_exit() -> void:
	get_tree().quit()

func set_respawn() -> void:
	respawn_pos = self.global_position
	respawn_rot = self.global_rotation

func apply_damage_filter() -> void:
	tween = create_tween()
	tween.tween_property(damage_filter, "color:a", 0.1, 0.2)

func remove_damage_filter() -> void:
	tween = create_tween()
	tween.tween_property(damage_filter, "color:a", 0.0, 0.2)

func increase_filter(length: float) -> void:
	tween = create_tween()
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/pixel_size", pixelization * 5, length)

func restore_filter(length: float) -> void:
	tween = create_tween()
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/pixel_size", pixelization, length)

func enable_impact() -> void:
	shader_mesh.get_material().set("shader_parameter/flash_amount", 1.0)
	shader_mesh.get_material().set("shader_parameter/flash_pivot", 0.114)
	shader_mesh.get_material().set("shader_parameter/flash_softness", 0.0)

func disable_impact() -> void:
	shader_mesh.get_material().set("shader_parameter/flash_amount", 0.0)
	shader_mesh.get_material().set("shader_parameter/flash_pivot", 0.5)
	shader_mesh.get_material().set("shader_parameter/flash_softness", 0.05)

func pause_effect() -> void:
	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/flash_amount", 1.0, 1.0)
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/flash_pivot", 1.0, 1.0)
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/flash_softness", 0.05, 1.0)
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/pixel_size", pixelization * 10, 1.0)
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/shadow_crush", 0.95, 1.0)
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/highlight_boost", 3.0, 1.0)
	
func unpause_effect() -> void:
	tween = create_tween()
	tween.set_parallel()
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/flash_amount", 0.0, 1.0)
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/flash_pivot", 0.5, 1.0)
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/flash_softness", 0.05, 1.0)
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/pixel_size", pixelization, 1.0)
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/shadow_crush", 0.0, 1.0)
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/highlight_boost", 0.0, 1.0)

func screen_fx_enable(vfxname: String) -> void:
	var vfx = interface.get_node("VFX/"+vfxname)
	if not vfx:
		printerr("PLAYER:\nVFX Node with that name does not exist")
		return
	else:
		vfx.visible = true
		
func screen_fx_disable(vfxname: String) -> void:
	var vfx = interface.get_node("VFX/"+vfxname)
	if not vfx:
		printerr("PLAYER:\nVFX Node with that name does not exist")
		return
	else:
		vfx.visible = false
	

func _on_settings() -> void:
	var settings
	@warning_ignore("shadowed_variable")
	var main_menu = $Interface/MainMenu
	if main_menu.visible:
		settings = $Interface/MainMenu/Settings
	else:
		settings = $Interface/Pause/Settings
		
	var main = settings.get_parent().get_node("Main")
	
	main.visible = !main.visible
	settings.visible = !settings.visible

func _on_main_menu_music_volume_change(value: float) -> void:
	Global.menu_volume = value
	menu_music_player.volume_db = Global.menu_volume
	Global.menu_volume_changed.emit(value)

func _on_sfx_volume_change(value: float) -> void:
	Global.sfx_volume = value
	sfx_player.volume_db = Global.sfx_volume
	Global.sfx_volume_changed.emit(value)

func _on_dialog_volume_change(value: float) -> void:
	Global.level_ambience_volume = value
	level_ambience.volume_db = Global.level_ambience_volume
	Global.level_ambience_volume_changed.emit(value)

func _on_level_music_value_change(value: float) -> void:
	Global.level_music_volume = value
	level_music.volume_db = Global.level_music_volume
	Global.level_music_volume_changed.emit(value)

func start_ambience(level_type, ambience_path, music_path = "") -> void:
	if level_type == current_ambience:
		return
	current_ambience = level_type
	stop_ambience()
	level_ambience.stream = load(ambience_path)
	if music_path:
		level_music.stream = load(music_path)
		level_music.play()
	level_ambience.play()

func stop_ambience() -> void:
	level_music.stop()
	level_ambience.stop()

func menu_play(path: String) -> void:
	menu_music_player.stream = load(path)
	menu_music_player.play()

func menu_stop() -> void:
	tween = create_tween()
	tween.tween_property(menu_music_player, "volume_db", -100.0, 3.0)
	await tween.finished
	menu_music_player.stop()

func load_sounds() -> void:
	var dir := DirAccess.open("res://audio/fooley/")
	if dir == null: printerr("PLAYER:\nCould not open folder"); return
	dir.list_dir_begin()
	for file: String in dir.get_files():
		var resource := dir.get_current_dir() + file
		var loaded = load(resource)
		if "Footstep" in resource:
			walking_sounds.append(loaded)

func _on_restart() -> void:
	if not root:
		root = get_parent()
	root.restart()

func set_knockback(dir: Vector3, vel: Vector3) -> void:
	being_knocked_back = 1
	knockback_velocity = vel
	knockback_dir = (global_position - dir).normalized()

func remove_knockback() -> void:
	being_knocked_back = 0

func apply_knockback(delta) -> void:
	velocity.x = knockback_velocity.x
	velocity.z = knockback_velocity.z
	knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, knockback_decay * delta)
	if knockback_velocity.length() < 1.5:
		remove_knockback()
		
func interact_with(button: int) -> void:
	var obj = interact.get_collider()
	if obj:
		label_max_speed.text = "Interacting with: " + obj.name
		print("Interacting with ", obj.name)
		if obj.has_method("interact"):
			obj.interact(button)
			
func set_gravity(amount: float) -> void:
	gravity = amount

func set_intro(title: String, desc: String) -> void:
	var t = $Interface/Intro/Title
	var d = $Interface/Intro/Desc
	t.text = title
	d.text = desc

func toggle_intro() -> void:
	var t = $Interface/Intro/Title
	var intro = $Interface/Intro
	tween = create_tween()
	print("PLAYER: Toggling intro")
	intro.visible = true
	var color = t.label_settings.font_color
	color.a = 1.0

	tween.tween_property(t.label_settings, "font_color", color, 2.0)
	await tween.finished
	await get_tree().create_timer(1.0).timeout
	tween = create_tween()
	color.a = 0.0
	tween.tween_property(t.label_settings, "font_color", color, 1.0)

func afford_puchase(amount: float) -> bool:
	if coins > amount:
		return true
	return false

func update_coins(amount: float) -> void:
	coins += amount
	coins_changed.emit(coins)
	
func load_screen(waittime: float):
	var texture_progress_bar: TextureProgressBar = $LoadingScreen/TextureProgressBar
	toggle_mouse()
	loading_screen.visible = true
	var elapsed := 0.0

	while elapsed < waittime:
		await get_tree().process_frame
		elapsed += get_process_delta_time()

		texture_progress_bar.value = lerp(
			texture_progress_bar.min_value,
			texture_progress_bar.max_value,
			elapsed / waittime
		)
	loading_screen.visible = false
	toggle_mouse()
