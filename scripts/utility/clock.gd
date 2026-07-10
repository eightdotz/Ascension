extends Node3D

@onready var label_3d: Label3D = $Label3D
@onready var timer := $Timer

func _ready():
	timer.wait_time = 1.0
	timer.timeout.connect(_on_timer_timeout)
	var time = Time.get_time_dict_from_system()
	label_3d.text = "%02d:%02d:%02d" % [time.hour, time.minute, time.second]
	
func _on_timer_timeout():
	var time = Time.get_time_dict_from_system()
	label_3d.text = "%02d:%02d:%02d" % [time.hour, time.minute, time.second]
