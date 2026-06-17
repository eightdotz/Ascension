extends CharacterBody3D

@export var health := 100.0
@export var stamina := 100.0
@export var health_max := 100.0
@export var stamina_max := 100.0
@export var stamina_build_passive := 40.0
@export var stamina_drain_sprint := 2.0
@export var stamina_drain_sidestep := 3.0
@export var stamina_drain_jump := 1.0

@export var invincibility_duration := 0.5
var is_invincible := false
var invincibility_timer := 0.0

@export var max_speed := 30.0
@onready var cache_max_speed := max_speed
var sprint_speed := 1.0
@export var accel := 700.0
@export var decel := 0.3
@export var air_speed := 1.5
@export var fall_speed := 5.0

@export var jump_cooldown := 0.2

@export var gravity := 50.0
@export var jump_speed := 50.0
@export var jump_max_held := 0.2
@export var wall_jump_force := 140.0
@export var wall_jump_force_init := 125.0
@export var jump_max := 3
@export var coyote_time := 0.2
@export var jump_buffer := 0.5
@export var mouse_sensitivity := 0.1
@export var wall_angle := 5.0
@export var max_wall_angle := 150.0
@export var wall_jump_velocity_preserve_time := 0.1
@export var wall_jump_velocity_max := 160

@export var base_fov := 75.0
@export var sprint_fov_boost := 5.0
@export var wall_jump_fov_boost := 25.0
@export var fov_lerp_speed := 8.0

@onready var player_head = $Head
@onready var camera = $Head/Camera3D

var in_water = false
var slow = 2

var cache_jump := jump_speed
var cache_accel := accel

var slow_accel := accel / 2
var slow_jump_speed := jump_speed / 2


var wall_jump_boost_timer := 0.0
var wall_jump_timer := 0.0
var wall_jump_velocity_preserve_timer := 0.0
var wall_stick_timer := 0.0
var jump_time := 0.0
var last_gnd_time := 0.0
var last_jump_time := 0.0

var wall_jump_speed_boost := 1.5
var wall_jump_boost_duration := 4.5
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

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		rotation_x = clamp(rotation_x - event.relative.y * mouse_sensitivity, -90, 90)
		$Head.rotation.x = deg_to_rad(rotation_x)

func _unhandled_input(_event):
	if Input.is_action_just_pressed("move_pause"):
		mouse_captured = !mouse_captured
		var mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE
		Input.set_mouse_mode(mode)

func _ready():
	jumps = jump_max
	$GNDRayCast.target_position = Vector3(0, -1.1, 0)
	$GNDRayCast.enabled = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")
	if camera:
		camera.fov = base_fov

func _process(delta):
	update_camera_fov(delta)
	update_stamina_and_timers(delta)

func _physics_process(delta):
	last_gnd_time += delta
	last_jump_time += delta
	
	if wall_jump_boost_timer > 0:
		wall_jump_boost_timer -= delta
		
		var time_progress = 1.0 - (wall_jump_boost_timer / wall_jump_boost_duration)
		var drag_factor = max(0.1, 0.6 - (time_progress * 0.5))
		
		var base_speed = cache_max_speed
		var boosted_speed = (base_speed * wall_jump_speed_boost) * drag_factor
		var speed_limit = (wall_jump_velocity_max / 2) - 20
		max_speed = max(base_speed, min(boosted_speed, speed_limit))
	else:
		max_speed = cache_max_speed
	
	if wall_jump_timer > 0:
		wall_jump_timer -= delta
		is_sliding = false
	else:
		update_wall_status()
	
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	direction = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	
	if is_sliding and wall_normal != Vector3.ZERO:
		var right_vector = transform.basis.x.normalized()
		var tilt_direction = wall_normal.cross(Vector3.UP).normalized()
		
		var tilt_amount_target = 0.0
		if right_vector.dot(tilt_direction) > 0:
			tilt_amount_target = -0.3
		else:
			tilt_amount_target = 0.3
		
		rotation.z = lerp(rotation.z, tilt_amount_target, 8 * delta)
	else:
		rotation.z = lerp(rotation.z, 0.0, 5 * delta)
	
	var grounded = is_on_floor() or $GNDRayCast.is_colliding()
	
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
	var max_horiz_speed = max_speed * (sprint_speed if Input.is_action_pressed("move_sprint") else 1.0)
	if wall_jump_velocity_preserve_timer > 0:
		wall_jump_velocity_preserve_timer -= delta
	else:
		if horiz.length() > max_horiz_speed:
			horiz = horiz.normalized() * max_horiz_speed
			velocity.x = horiz.x
			velocity.z = horiz.y
		just_wall_jumped = false
		handle_move(delta, grounded)
	
	move_and_slide()

func update_stamina_and_timers(delta):
	if not Input.is_action_pressed("move_sprint"):
		stamina += stamina_build_passive * delta
		stamina = min(stamina, stamina_max)
	
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false

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

func get_body_center() -> Vector3:
	return global_position + Vector3(0, -0.8, 0)

func handle_move(delta: float, grounded: bool):
	var control_force = 1.0 if grounded else air_speed
	if direction != Vector3.ZERO:
		if Input.is_action_pressed("move_sprint") and stamina > stamina_drain_sprint:
			sprint_speed = 2
			stamina -= stamina_drain_sprint * delta
			stamina = max(stamina, 0.0)
		else:
			sprint_speed = 1
		var target_vel = (direction * max_speed) * sprint_speed
		velocity.x = move_toward(velocity.x, target_vel.x, accel * delta * control_force)
		velocity.z = move_toward(velocity.z, target_vel.z, accel * delta * control_force)
	else:
		var damp = decel * control_force
		velocity.x *= damp
		velocity.z *= damp

func handle_jump_buffer(_delta: float, grounded: bool):
	if Input.is_action_just_pressed("move_jump") and last_jump_time > jump_cooldown:
		print("Jump pressed!")
		if is_sliding and jumps > 0:
			print("Trying wall jump!")
			do_wall_jump()
		elif jumps > 0 and grounded:
			print("Doing ground jump")
			do_jump(Vector3.UP)
		elif jumps > 0:
			print("Doing midair jump")
			do_jump(Vector3.UP)

func do_jump(direction: Vector3):
	if stamina < stamina_drain_jump:
		return
	is_jumping = true
	stamina -= stamina_drain_jump
	stamina = max(stamina, 0.0)
	jump_time = 0.0
	jumps -= 1
	last_jump_time = 0.0
	velocity.y = direction.y * jump_speed

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
	last_jump_time = 0.0
	wall_jump_timer += jump_cooldown
	just_wall_jumped = true
	wall_jump_velocity_preserve_timer = wall_jump_velocity_preserve_time
	wall_jump_boost_timer += wall_jump_boost_duration

	print("WALL JUMP - velocity clamped to:", velocity.length(), "max allowed:", max_wall_jump_speed)

func update_wall_status():
	
	var input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var input_dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	var has_input = input.length() > 0.001
	
	var found_wall = false
	var new_wall_normal = Vector3.ZERO
	
	for ray in $WallCast.get_children():
		if ray.is_colliding():
			var normal = ray.get_collision_normal()
			var angle_deg = rad_to_deg(acos(normal.dot(Vector3.UP)))
			
			if angle_deg > wall_angle and angle_deg < max_wall_angle:
				var to_wall = -normal.normalized()
				var toward_wall = has_input and input_dir.dot(to_wall) > 0.1
				
				if toward_wall or (is_sliding and wall_normal.dot(normal) > 0.7):
					new_wall_normal += normal
					found_wall = true
	
	if found_wall and not is_on_floor() and last_gnd_time > 0.1:
		if not is_sliding:
			wall_stick_timer = wall_stick_duration
			jumps = jump_max
		
		wall_normal = new_wall_normal.normalized()
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
		
	is_invincible = true
	invincibility_timer = invincibility_duration
	flash_screen_red()
	
	if health <= 0:
		handle_death()
	
	return damage_dealt

func flash_screen_red():
	print("Player hit! Screen should flash red")

func handle_death():
	print("Player died!")
	await get_tree().create_timer(2.0).timeout
	respawn_player()

func respawn_player():
	health = health_max
	print("Player respawned!")
	global_position = Vector3(-464, 1, 0)

func is_player():
	return 1
