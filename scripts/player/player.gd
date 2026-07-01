extends CharacterBody3D

@export var diagnostics_enabled: bool = false
@export var root: Node3D = get_parent() 

@export_group("Abilities")
@export var ability_1: Ability
@export var ability_2: Ability
@export var ability_3: Ability

@export_group("Health")
@export var health := 100.0 ##Player starting health
@export var health_max := 100.0 ##The maximum health that the player can heal to
@export var regen := 0.1 ##Amount of health regenerated per delta
@export var invincibility_duration := 0.5 ##Duration in seconds of invulnerability after being hit

@export_group("Stamina")
@export var stamina := 100.0 ##Player starting stamina
@export var stamina_max := 100.0 ##Maximum stamina that can be regenerated
@export var stamina_build_passive := 40.0 ##Amount of stamina build passively * delta
@export var stamina_drain_sprint := 1.0 ##Stamina drain from sprinting * delta
@export var stamina_drain_jump := 0.5 ##Stamina drain from jumping 


var is_invincible := false
var invincibility_timer := 0.0
@export_group("Speed")
@export var max_speed := 30.0 ##Max speed with no modifiers or sprint
@export var air_speed := 1.5 ##The amount of control while in air
@export var fall_speed := 5.0 ##The speed at which the player decends while holding ctrl
@export var accel := 700.0 ##Acceleration from stop
@export var decel := 0.3 ##Decceleration from current velocity
@export var gravity := 50.0 ##You know what this means
@export var jump_speed := 50.0 ##Speed at which the player departs from surface

@export_group("Jump")
@export var jump_max := 3 ##Amount of jumps avaliable
@export var jump_cooldown := 0.2 ##Length in seconds between jumps to prevent spamming
@export var jump_max_held := 0.2 ##Allows for higher jumps when pressed longer

@export var mouse_sensitivity := 0.1 ##Sensitivity

@export_group("Wall Jump")
@export var wall_jump_force := 140.0 ##Speed of a jump when departing from a wall
@export var wall_jump_force_init := 125.0 ##The initial speed burst when performing a wall jump
@export var wall_angle := 5.0 ##Minimum angle for walls to be jumped off of
@export var max_wall_angle := 150.0 ##Maximum angle for walls to be jumped off of
@export var straight_wall_leeway = 3 ##The amount of range to or from 90 degrees that is accepted as a "straight wall" or surface that cannot be jumped off of
@export var wall_jump_velocity_preserve_time := 0.2 ##Amount of time top speed is preserved
@export var wall_jump_velocity_max := 160 ##Maximum speed with any boost
@export var wall_jump_speed_boost := 1.5
@export var wall_jump_boost_duration := 4.5
@export var wall_jump_boost_timer := 0.0
@export var wall_jump_timer := 0.0

@export_group("FOV")
@export var base_fov := 75.0 ##Default field of view
@export var sprint_fov_boost := 5.0 ##The amount field of view increases while sprinting
@export var wall_jump_fov_boost := 25.0 ##The amount field of view can increase during a wall jump or max speed
@export var fov_lerp_speed := 8.0 ##The speed at which the field of view changes

@export_group("Shader")
@export_range (0.0, 100.0, 0.1) var pixelization: float
@onready var shader_mesh: ColorRect = $Interface/HUD/PixelFilter

@onready var cache_max_speed := max_speed
@onready var player_head = $Head
@onready var camera = $Head/Camera

enum SpeedMod {SPRINT, WALL_JUMP_BOOST, BOOST, SLOW}
var _speed_modifiers: Dictionary = {}

var movement_override_timer := 0.0 #while > 0, the normal speed clamp/accel is skipped. Used by wall jump and dash.

var wall_stick_timer := 0.0
var jump_time := 0.0
var last_gnd_time := 0.0
var last_jump_time := 0.0

var tilt_amount = 0.1
var rotation_x := 0.0

var mouse_captured := true
var direction := Vector3.ZERO
var wall_normal := Vector3.ZERO
var jumps := 0
var is_jumping := false
var is_sliding := false
var just_wall_jumped := false

var wall_slide_speed := 10.0
var wall_stick_duration := 0.3
var wall_stick_velocity_threshold := 5.0

var tween = null
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
@onready var bar_health: ProgressBar = $Interface/HUD/Health
@onready var bar_stamina: ProgressBar = $Interface/HUD/Stamina
@onready var bar_jumps: ProgressBar = $Interface/HUD/Jumps
@onready var black_screen: ColorRect = $Interface/HUD/BlackScreen
@onready var hud: Control = $Interface/HUD
@onready var level: Label = $Interface/HUD/Level
@onready var pause: Control = $Interface/Pause
@onready var main_menu: Control = $Interface/MainMenu
@onready var damage_filter: ColorRect = $Interface/HUD/DamageFilter

var respawn_pos: Vector3
var respawn_rot: Vector3

#mouse signals
signal on_click

func _ready():
	if diagnostics_enabled:
		diagnostics.visible = true
	else:
		diagnostics.visible = false
	jumps = jump_max
	bar_jumps.value = jump_max
	gnd_ray.target_position = Vector3(0, -1.1, 0)
	gnd_ray.enabled = true
	add_to_group("player")
	if camera:
		camera.fov = base_fov
	shader_mesh.get_material().set("shader_parameter/pixel_size",pixelization)
	toggle_mouse()
	set_process_input(!is_processing_input())

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		rotation_x = clamp(rotation_x - event.relative.y * mouse_sensitivity, -90, 90)
		player_head.rotation.x = deg_to_rad(rotation_x)
	else:
		if event is InputEventMouseButton:
			if event.button_index and event.is_pressed():
				_on_click(event.button_index)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("move_pause"):
		_on_menu_button_pressed()

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
	label_boost_duration.text = str(wall_jump_boost_timer)
	var time_progress = 1.0 - (wall_jump_boost_timer / wall_jump_boost_duration)
	var drag_factor = max(0.1, 0.6 - (time_progress * 0.5))
	var boosted_speed = cache_max_speed * wall_jump_speed_boost * drag_factor
	var speed_limit = (wall_jump_velocity_max / 2.0) - 20
	var clamped_speed = max(cache_max_speed, min(boosted_speed, speed_limit))
	add_speed_modifier(SpeedMod.WALL_JUMP_BOOST, clamped_speed / cache_max_speed)

var cos_wall_angle_min := cos(deg_to_rad(wall_angle))
var cos_wall_angle_max := cos(deg_to_rad(max_wall_angle))
var cos_straight_min := cos(deg_to_rad(90 - straight_wall_leeway))
var cos_straight_max := cos(deg_to_rad(90 + straight_wall_leeway))

func _process(delta):
	update_camera_fov(delta)
	update_stamina_and_timers(delta)

func _physics_process(delta):
	last_gnd_time += delta
	last_jump_time += delta
	
	_update_sprint_modifier(delta)
	_update_wall_jump_boost(delta)
	_update_speed_modifiers(delta)
	max_speed = get_effective_max_speed()
	label_max_speed.text = "Effective Max Speed: " + str(max_speed)
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	direction = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
		is_sliding = false
	else:
		update_wall_status(direction)
	label_direction.text = "Moving Direction: " + str(direction)
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
	label_mv_override.text = "Engine Time: " + str(Engine.time_scale)
	label_current_speed.text = "Current Speed: " + str(max_horiz_speed)
	label_sliding.text = "Is Character Sliding: " + str(is_sliding)
	move_and_slide()

func update_stamina_and_timers(delta):
	if not Input.is_action_pressed("move_sprint"):
		stamina += stamina_build_passive * delta
		stamina = min(stamina, stamina_max)
	
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
	bar_health.value = health
	bar_stamina.value = stamina

func update_camera_fov(delta):
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
	label_fov.text = "Field of View: " + str(camera.fov)
func get_body_center() -> Vector3:
	return global_position + Vector3(0, -0.8, 0)

func handle_move(delta: float, grounded: bool):
	var control_force = 1.0 if grounded else air_speed
	if direction != Vector3.ZERO:
		var target_vel = direction * max_speed
		velocity.x = move_toward(velocity.x, target_vel.x, accel * delta * control_force)
		velocity.z = move_toward(velocity.z, target_vel.z, accel * delta * control_force)
	else:
		var damp = decel * control_force
		velocity.x *= damp
		velocity.z *= damp

func handle_jump_buffer(_delta: float, grounded: bool):
	if Input.is_action_just_pressed("move_jump"):
		if last_jump_time > jump_cooldown:
			if is_sliding and jumps > 0:
				do_wall_jump()
			elif jumps > 0 and grounded:
				do_jump(Vector3.UP)
			elif jumps > 0:
				do_jump(Vector3.UP)

func do_jump(new_direction: Vector3):
	if stamina < stamina_drain_jump:
		return
	is_jumping = true
	stamina -= stamina_drain_jump
	stamina = max(stamina, 0.0)
	jump_time = 0.0
	jumps -= 1
	bar_jumps.value = jumps
	last_jump_time = 0.0
	velocity.y = new_direction.y * jump_speed

func do_wall_jump():
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
	bar_jumps.value = jumps
	last_jump_time = 0.0
	wall_jump_timer += jump_cooldown
	just_wall_jumped = true
	movement_override_timer = wall_jump_velocity_preserve_time
	wall_jump_boost_timer += wall_jump_boost_duration

func update_wall_status(input_dir):
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
					label_wall_angle.text = str(normal)
					found_wall = true
					break
	if found_wall and not is_on_floor() and last_gnd_time > 0.1:
		if not is_sliding:
			wall_stick_timer = wall_stick_duration
			jumps = jump_max
			bar_jumps.value = jumps
		
		wall_normal = wall_normal.normalized()
		is_sliding = true
		
		if wall_stick_timer > 0.0:
			wall_stick_timer -= get_physics_process_delta_time()
			Engine.time_scale = 0.7
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
		Engine.time_scale = 1.0

func take_damage(damage: float) -> float:
	if is_invincible or health <= 0:
		return 0.0
	
	var damage_dealt = min(damage, health)
	health -= damage_dealt
		
	is_invincible = true
	invincibility_timer = invincibility_duration
	flash_screen_red()
	
	if health <= 0:
		handle_death()
	
	return damage_dealt

func flash_screen_red():
	print("Player hit! Screen should flash red")

func handle_death():
	await get_tree().create_timer(2.0).timeout
	respawn_player()

func respawn_player():
	health = health_max
	self.global_position = respawn_pos
	self.global_rotation = respawn_rot

func is_player():
	return 1

#HUD
func toggle_mouse():
	mouse_captured = !mouse_captured
	var mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE
	Input.warp_mouse((hud.get_viewport_rect().size / 2.0))
	Input.set_mouse_mode(mode)

func disable_mouse():
	set_process_input(false)

func enable_mouse():
	set_process_input(true)

func disable_movement():
	set_physics_process(false)
	set_process_unhandled_input(false)
	
func enable_movement():
	set_physics_process(true)
	set_process_unhandled_input(true)
	
func fade_to_black(time: float = 0.5, wait:bool = false):
	black_screen.color.a = 0.0
	tween = create_tween()
	tween.tween_property(black_screen, "color:a", 1.0, time)
	if wait:
		await tween.finished

func fade_to_clear(time: float = 0.5, wait:bool = false):
	black_screen.color.a = 1.0
	tween = create_tween()
	tween.tween_property(black_screen, "color:a", 0.0, time)
	if wait:
		await tween.finished

func get_mouse():
	return get_viewport().get_mouse_position()

func _on_click(button: int) -> void:
	emit_signal("on_click", button)
	
func upgrade(upgrade_name: String, amount: float):
	var upgradables = {"Max Health": health_max, "Regeneration": regen, "Max Stamina": stamina_max, "Max Speed": max_speed, "Jump Quanity":jumps, "Jump Height":jump_speed, "Wall Jump Boost Duration":wall_jump_boost_duration, "Wall Jump Speed": wall_jump_force, "Wall Jump Max Speed":wall_jump_velocity_max}
	print("Upgrading " + upgrade_name + " by " + str(amount))
	upgradables[upgrade_name] += amount


func add_ability(new_ability: Ability):
	if new_ability.type == "Upgrade":
		print("Upgrading")
		new_ability.execute(self)
		return
	print("Assigning")
	if not ability_1:
		ability_1 = new_ability
	elif not ability_2:
		ability_2 = new_ability
	elif not ability_3:
		ability_3 = new_ability
	else:
		overwrite_ability(new_ability)

func overwrite_ability(new_ability: Ability):
	pass

func _on_root_level_changed() -> void:
	print("Level Changed")
	if root:
		print("Found Root")
		if root.get_level_type() == "Ability":
			print("Level Type is ability")
			var dungeon = root.dungeon
			if dungeon:
				if on_click.is_connected(dungeon._on_click):
					on_click.disconnect(dungeon._on_click)
				on_click.connect(dungeon._on_click)

func set_level(value: String):
	tween = create_tween()
	tween.tween_property(level, "modulate:a", 0.0, 2.0)
	await tween.finished
	level.text = value
	tween = create_tween()
	tween.tween_property(level, "modulate:a", 1.0, 2.0)

func get_level():
	return level.text

func reset_timers():
	wall_jump_boost_timer = 0.0
	movement_override_timer = 0.0
	wall_jump_timer = 0.0


func _on_menu_button_pressed() -> void:
	set_process_input(!is_processing_input())
	pause.visible = !pause.visible
	toggle_mouse()
	if pause.visible:
		Engine.time_scale = 0
	else:
		Engine.time_scale = 1


func _start_game() -> void:
	main_menu.visible = !main_menu.visible
	toggle_mouse()
	set_process_input(!is_processing_input())


func _on_exit() -> void:
	get_tree().quit()

func set_respawn():
	respawn_pos = self.global_position
	respawn_rot = self.global_rotation

func apply_damage_filter():
	tween = create_tween()
	tween.tween_property(damage_filter, "color:a", 0.1, 0.2)

func remove_damage_filter():
	tween = create_tween()
	tween.tween_property(damage_filter, "color:a", 0.0, 0.2)

func increase_filter(length: float):
	tween = create_tween()
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/pixel_size", pixelization * 5, length)

func restore_filter(length: float):
	tween = create_tween()
	tween.tween_property(shader_mesh.get_material(), "shader_parameter/pixel_size", pixelization, length)

func impact():
	shader_mesh.get_material().set("shader_parameter/flash_amount", 1.0)
	shader_mesh.get_material().set("shader_parameter/flash_pivot", 0.114)
	shader_mesh.get_material().set("shader_parameter/flash_softness", 0.0)
	Engine.time_scale = 0.0
	await get_tree().create_timer(0.25).timeout
	shader_mesh.get_material().set("shader_parameter/flash_amount", 0.0)
	shader_mesh.get_material().set("shader_parameter/flash_pivot", 0.5)
	shader_mesh.get_material().set("shader_parameter/flash_softness", 0.05)
	Engine.time_scale = 1.0
