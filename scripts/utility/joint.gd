extends Node3D

@onready var attachment_point: MeshInstance3D = $AttachmentPoint

func _ready() -> void:
	attachment_point.visible = true
