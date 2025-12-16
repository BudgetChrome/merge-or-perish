extends StaticBody3D

@export var Health: int = 2

func Hit_Successful(damage: int, _Direction: Vector3 = Vector3.ZERO, _Position: Vector3 = Vector3.ZERO) -> void:
	Health -= damage
	print("Hit! Health now:", Health)
	if Health <= 0:
		print("Enemy died")
		queue_free()
