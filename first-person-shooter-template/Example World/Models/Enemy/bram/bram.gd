extends CharacterBody3D

# ================= НАСТРОЙКИ =================
@export var SPEED: float = 5.0
@export var ROTATION_SPEED: float = 8.0


@onready var health_bar: ProgressBar = $Node3D/SubViewport/Control/ProgressBar
@onready var name_label: Label = $Node3D/SubViewport/Control/Label

@export var MAX_CHASE_DISTANCE: float = 15.0
@export var ATTACK_DISTANCE: float = 2.0

@export var ATTACK_DAMAGE: int = 10
@export var ATTACK_COOLDOWN: float = 1.5

@export var MAX_HEALTH: int = 1000
@export var player_path: NodePath

# ================= ССЫЛКИ =================
@onready var skin: Node3D = $"Orc Idle"
@onready var animation_player: AnimationPlayer = $"Orc Idle"/AnimationPlayer
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

# ================= ПЕРЕМЕННЫЕ =================
var player: Node3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") as float

var health: int
var attack_timer := 0.0

var dood := false
var rage := false
var hit_anim_playing := false

# ================= READY =================
func _ready() -> void:
	player = get_node(player_path)
	health = MAX_HEALTH
	nav_agent.target_desired_distance = 0.1
	
	health_bar.max_value = MAX_HEALTH
	health_bar.value = health
	#name_label.text = "ORC WARLORD"
	
	skin.rotation.y = deg_to_rad(180)

# ================= PHYSICS =================
func _physics_process(delta: float) -> void:
	if player == null or dood:
		return

	var distance := global_position.distance_to(player.global_position)

	if distance > MAX_CHASE_DISTANCE:
		_stop_movement()
		return

	nav_agent.set_target_position(player.global_position)

	# гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	attack_timer -= delta

	# движение
	var direction := Vector3.ZERO
	if not nav_agent.is_navigation_finished():
		direction = nav_agent.get_next_path_position() - global_position
		direction.y = 0

		if direction.length() > 0.01:
			direction = direction.normalized()

			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED

			# поворот к игроку
			var look_pos = player.global_position
			look_pos.y = global_position.y
			skin.look_at(look_pos, Vector3.UP)
			skin.rotate_y(deg_to_rad(180))


			if not hit_anim_playing:
				animation_player.play("Unarmed Run Forward/mixamo_com")
	else:
		_stop_movement()

	# атака
	if distance <= ATTACK_DISTANCE and attack_timer <= 0:
		_attack_player()

	move_and_slide()

# ================= MOVEMENT =================
func _stop_movement() -> void:
	velocity.x = 0
	velocity.z = 0
	if not hit_anim_playing:
		animation_player.play("mixamo_com")

# ================= ATTACK =================
func _attack_player() -> void:
	attack_timer = ATTACK_COOLDOWN

	velocity.x = 0
	velocity.z = 0

	animation_player.play("Boxing/mixamo_com")
	await animation_player.animation_finished

	if player.has_method("take_damage"):
		player.take_damage(ATTACK_DAMAGE)



# ================= DAMAGE =================
func Hit_Successful(damage: int, _dir := Vector3.ZERO, _pos := Vector3.ZERO) -> void:
	if dood:
		return

	health -= damage
	health_bar.value = health
	$Node3D.visible = true

	
	print("Boss HP:", health)

	# hit-анимация без стана
	if not hit_anim_playing:
		hit_anim_playing = true
		animation_player.play("Stomach Hit/mixamo_com")
		await animation_player.animation_finished
		hit_anim_playing = false

	# фаза ярости
	if health <= MAX_HEALTH * 0.5 and not rage:
		_enter_rage()

	# смерть
	if health <= 0:
		_die()

# ================= RAGE =================
func _enter_rage() -> void:
	rage = true
	SPEED *= 1.5
	ATTACK_COOLDOWN *= 0.6
	print("BOSS ENRAGED!")

# ================= DEATH =================
func _die() -> void:
	dood = true
	set_physics_process(false)

	velocity = Vector3.ZERO
	nav_agent.set_target_position(global_position)

	animation_player.play("Mutant Dying/mixamo_com")
	await get_tree().create_timer(5.5).timeout
	$Node3D.visible = false

	queue_free()
