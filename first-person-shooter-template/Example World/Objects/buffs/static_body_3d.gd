extends StaticBody3D

class_name Pizza

@export var item_name: String = "Pizza"

var pick_up_ready: bool = false

func _ready():
	# Ждём 2 секунды перед возможностью подбора
	await get_tree().create_timer(2.0).timeout
	pick_up_ready = true

func try_pick_up(player: Node) -> void:
	if not pick_up_ready:
		return
	pick_up(player)

func pick_up(player: Node) -> void:
	print(player.name, "подобрал предмет:", name)
	queue_free()  # удаляем пиццу из сцены
