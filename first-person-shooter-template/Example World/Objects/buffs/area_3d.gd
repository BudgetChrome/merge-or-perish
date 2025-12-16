extends Area3D

#@export var heal_amount: int = 25

func _on_body_entered(body):
	if (body.name == "player"):
		body.set_sprint_cooldown(20)
		queue_free()
	
