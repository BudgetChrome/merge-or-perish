extends CharacterBody3D

@export var SPEED: float = 5
@export var player_path: NodePath
@onready var skin: Node3D = $Idle

@export var ROTATION_SPEED: float = 8.0
@export var MAX_CHASE_DISTANCE: float = 15.0
@export var ATTACK_DISTANCE: float = 2.0
@export var ATTACK_DAMAGE: int = 10
@export var ATTACK_COOLDOWN: float = 1.5

@export var Health: int = 100

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $Idle/AnimationPlayer

var player: Node3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float
var attack_timer: float = 0.0
var dood := false
var is_hit := false

func _ready() -> void:
	player = get_node(player_path)
	nav_agent.target_desired_distance = 0.1


func _stop_movement() -> void:
	velocity.x = 0
	velocity.z = 0
	animation_player.play("mixamo_com")


func _physics_process(delta: float) -> void:
	if player == null or dood or is_hit:
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player > MAX_CHASE_DISTANCE:
		_stop_movement()
		return

	nav_agent.set_target_position(player.global_position)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	attack_timer -= delta

	var direction = Vector3.ZERO
	if not nav_agent.is_navigation_finished():
		var next_point = nav_agent.get_next_path_position()
		direction = next_point - global_position
		direction.y = 0

		if direction.length() > 0.01:
			direction = direction.normalized()

			var look_pos = player.global_position
			look_pos.y = global_position.y
			skin.look_at(look_pos, Vector3.UP)

			animation_player.play("Running(1)/mixamo_com")
		else:
			direction = Vector3.ZERO

	if distance_to_player <= ATTACK_DISTANCE and attack_timer <= 0:
		_attack_player()

	var move_speed = SPEED
	if distance_to_player < ATTACK_DISTANCE:
		move_speed *= 0.3

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	move_and_slide()



func _attack_player() -> void:
	attack_timer = ATTACK_COOLDOWN
	animation_player.play("Punching Bag/mixamo_com")
	
	if player.has_method("take_damage"):
		player.take_damage(ATTACK_DAMAGE)


func Hit_Successful(damage: int, _Direction: Vector3 = Vector3.ZERO, _Position: Vector3 = Vector3.ZERO):
	if dood:
		return
	
	Health -= damage
	
	is_hit = true

	velocity = Vector3.ZERO
	animation_player.play("Head Hit(1)/mixamo_com")
	print("Got hit! Health:", Health)

	await animation_player.animation_finished
	is_hit = false
	print("Got hit! Health now:", Health)
	
	if Health <= 0:
		dood = true
		
		velocity = Vector3.ZERO
		set_physics_process(false)
		nav_agent.set_target_position(global_position)

		animation_player.play("Dying/mixamo_com")

		await get_tree().create_timer(5.5).timeout
		queue_free()
