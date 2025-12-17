extends Node3D

@onready var name_ui := $"."

func _process(_delta):
	var cam := get_viewport().get_camera_3d()
	if cam:
		name_ui.look_at(cam.global_position, Vector3.UP)
