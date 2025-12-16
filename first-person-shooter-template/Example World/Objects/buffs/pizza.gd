extends Area3D

@export var heal_amount: int = 25

func _on_body_entered(body):
	if (body.name == "player" and body.health < 100):
		body.heal(25)
		queue_free()
	
