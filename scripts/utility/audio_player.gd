extends AudioStreamPlayer


@export var loop: bool = false

func _on_finished() -> void:
	if loop:
		self.play()
