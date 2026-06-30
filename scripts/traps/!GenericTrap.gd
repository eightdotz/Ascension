extends Node3D

@onready var construction: Node3D = $Lazer/Construction #No change
@onready var animation_player: AnimationPlayer = get_parent().get_node("AnimationPlayer") #No change
@onready var lights = $"../..".get_node("Lighting").get_children() #No change
@export var idle_animation_name = ""
@export var action_animation_name = ""
@export var hide_mesh_until_trigger: bool = false
@export var turn_off_lights: bool = false
@export var destroy_trap_on_end: bool = true


var err = 0

func _ready():
	if not lights:
		printerr("No lights in scene! Disabling light turn off")
		err = 1
	if not animation_player:
		printerr("No Anim Player in scene! Functionality will break!")
		err = 1
	if err:
		printerr("Please check your specifications! This scene does not appear to be compliant!")
	if hide_mesh_until_trigger:
		construction.visible = false
	if idle_animation_name:
		animation_player.play(idle_animation_name)

func _detect_player(body: Node3D) -> void:
	if body.has_method("is_player"):
		if turn_off_lights:
			if lights:
				for item in lights:
					item.toggle = false
		construction.visible = true
		if action_animation_name:
			animation_player.play(action_animation_name)
			await animation_player.animation_finished
			if destroy_trap_on_end:
				queue_free()
		if lights:
			for item in lights:
				item.toggle = true


func _detect_hitbox(body: Node3D) -> void:
	if body.has_method("is_player"):
		body.take_damage(10)
