extends CharacterBody3D

@export var SPEED: float = 5.0
@export var ROTATION_SPEED: float = 10.0
@export var MAX_CHASE_DISTANCE: float = 30.0
@export var ATTACK_DISTANCE: float = 1.0
@export var ATTACK_DAMAGE: int = 15
@export var ATTACK_COOLDOWN: float = 3.0
@export var Health: int = 150
@export var player_path: NodePath

@onready var skin: Node3D = $Idle
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $Idle/AnimationPlayer

var player: Node3D
var gravity := ProjectSettings.get_setting("physics/3d/default_gravity") as float
var attack_timer := 0.0
var dood := false
var is_hit := false

func _ready() -> void:
	player = get_node_or_null(player_path)
	nav_agent.target_desired_distance = 0.1


func _physics_process(delta: float) -> void:
	if player == null or dood or is_hit:
		return

	var distance := global_position.distance_to(player.global_position)

	if distance > MAX_CHASE_DISTANCE:
		_stop()
		return

	_rotate_to_player(delta)

	nav_agent.set_target_position(player.global_position)

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	attack_timer -= delta

	var direction := Vector3.ZERO
	if not nav_agent.is_navigation_finished():
		direction = nav_agent.get_next_path_position() - global_position
		direction.y = 0

		if direction.length() > 0.01:
			direction = direction.normalized()
			animation_player.play("Standard Run/mixamo_com")
		else:
			animation_player.play("mixamo_com")

	# Атака
	if distance <= ATTACK_DISTANCE and attack_timer <= 0.0:
		_attack()

	var speed := SPEED
	if distance <= ATTACK_DISTANCE:
		speed *= 0.3

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()


func _rotate_to_player(delta: float) -> void:
	var dir := player.global_position - global_position
	dir.y = 0

	if dir.length() < 0.01:
		return

	var target_basis := Basis().looking_at(-dir.normalized(), Vector3.UP)
	skin.global_transform.basis = skin.global_transform.basis.slerp(
		target_basis,
		ROTATION_SPEED * delta
	)


func _attack() -> void:
	attack_timer = ATTACK_COOLDOWN
	animation_player.play("Combo Punch/mixamo_com")

	if player.has_method("take_damage"):
		player.take_damage(ATTACK_DAMAGE)


func _stop() -> void:
	velocity.x = 0
	velocity.z = 0
	animation_player.play("mixamo_com")


func Hit_Successful(damage: int, _dir := Vector3.ZERO, _pos := Vector3.ZERO) -> void:
	if dood or is_hit:
		return

	Health -= damage
	is_hit = true

	velocity = Vector3.ZERO
	animation_player.play("Head Hit/mixamo_com")
	print("Got hit! Health:", Health)

	await animation_player.animation_finished
	is_hit = false

	if Health <= 0:
		_die()



func _die() -> void:
	dood = true
	velocity = Vector3.ZERO
	nav_agent.set_target_position(global_position)

	animation_player.play("Dying(1)/mixamo_com")
	await get_tree().create_timer(5.5).timeout
	queue_free()
