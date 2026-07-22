extends Node3D

@onready var construction: Node3D = $Construction
@onready var lights = $"../../MainBody/Lighting" #No change
@export var animation_player: AnimationPlayer

@export_group("Damage")
@export var do_damage: bool ##Enables or disables the ability to a random amount of damage
@export var min_damage: int ##Minimum amount of damage within range
@export var max_damage: int ##Maximum amount of damage within range
@export_group("Speed Effects")
@export var slow_player: bool ##Enables slowing of player
@export var intensity: float ##How much to the player slows. 1 = normal speed, 2 = double speed, 0.5 = half speed
@export var duration: float ##How long it lasts
@export_group("Animations")
@export var blur_screen: bool
@export var idle_animation_name = "" ##Name of idle animation within parent scene. Typing in a name will assume activation on ready
@export var action_animation_name = "" ##Name of action animation within parent scene trigged by detection zone. Typing in a name assumes it will be used on activation
@export var hide_mesh_until_trigger: bool = false ##Hides the meshes of an object until player is detected. This does not effect hitboxes
@export var destroy_detection_on_end: bool = false
@export_group("Light Control")
@export var turn_off_lights: bool = false ##Searches for and turns off lights within parent scene
@export var colors: Array[Color] ##Colors that will be cycled through
@export var lasting_color_duration: float = 1.0
@export var tween_duration: float = 1.0 ##Time between cycles

@export var destroy_trap_on_end: bool = true
@onready var damage_area: Area3D = $DamageArea
@onready var detect_area: Area3D

enum SpeedMod {SPRINT, WALL_JUMP_BOOST, BOOST, SLOW}

var err = 0

func _ready() -> void:
	if lights:
		lights = lights.get_children()
	detect_area = $DetectArea
	if not lights:
		printerr("No lights in scene! Disabling light turn off")
		err = 1
	if not animation_player:
		printerr("No Anim Player in scene! Functionality will break!")
		err = 1
	else:
		if idle_animation_name:
			print("Playing idle animation: ", idle_animation_name)
			animation_player.play(idle_animation_name)
	if err:
		printerr("Please check your specifications! This scene does not appear to be compliant!")
	if hide_mesh_until_trigger:
		construction.visible = false

func _detect_player(body: Node3D) -> void:
	if body.has_method("is_player"):
		lights_off()
		construction.visible = true
		if action_animation_name and animation_player:
			animation_player.play(action_animation_name)
			await animation_player.animation_finished
			if destroy_trap_on_end:
				queue_free()
			elif destroy_detection_on_end:
				detect_area.queue_free()
		lights_on()

func lights_on() -> void:
	if lights:
		for item in lights:
			item.toggle = true

func lights_off() -> void:
	if turn_off_lights:
			if lights:
				for item in lights:
					item.toggle = false

func _detect_hitbox(body: Node3D) -> void:
	if body.has_method("is_player"):
		print(self.name + " is hitting player from " + get_parent().get_parent().name)
		if slow_player:
			body.add_speed_modifier(SpeedMod.SLOW, intensity)
		if blur_screen:
			body.increase_filter(0.3)
		if do_damage:
			body.take_damage(randi_range(min_damage, max_damage))
		if slow_player:
			await get_tree().create_timer(duration).timeout
			body.remove_speed_modifier(SpeedMod.SLOW)
		if blur_screen:
			body.restore_filter(1.0)
			
			
func disable_hitbox() -> void:
	damage_area.monitoring = false

func enable_hitbox() -> void:
	damage_area.monitoring = true
