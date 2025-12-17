extends Control

@onready var start_button: Button = $StartButton

func _ready():
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed():
	print("Game starting!")
	get_tree().change_scene_to_file("res://Example World/Objects/World/world.tscn")
