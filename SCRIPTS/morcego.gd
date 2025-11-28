extends CharacterBody2D

const SPEED = 80.0
const CHASE_SPEED = 120.0
const MIN_DISTANCE_FROM_WALL = 30.0

# Estados do morcego
enum State { PATROL, CHASE, HURT, DEAD }
var current_state = State.PATROL

# Variáveis de vida e estado
var max_health := 3
var current_health := 3
var is_dead := false

var original_y := 0.0

@onready var texture := $texture
@onready var animation_player := $anim
@onready var detection_area := $DetectionArea
@onready var wall_detector := $wall_detector
@onready var hurtbox := $hitbox  # Área para receber dano (já existe na sua cena)

var player_ref: CharacterBody2D = null
var direction := 1

var random_timer := 0.0
var random_time := 1.5 + randf() * 3.0

func _ready():
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	hurtbox.body_entered.connect(_on_hurtbox_body_entered)  # Conecta o sinal de dano
	
	original_y = global_position.y
	current_health = max_health

	wall_detector.enabled = true
	wall_detector.collide_with_bodies = true
	wall_detector.collide_with_areas = false

	print("🦇 Morcego ativo! Vida: ", current_health, "/", max_health)

func _physics_process(delta: float) -> void:
	if is_dead or current_state == State.DEAD:
		return
		
	wall_detector.target_position.x = 40 * direction
	
	# Máquina de estados
	match current_state:
		State.PATROL:
			patrol_behavior(delta)
		State.CHASE:
			chase_behavior(delta)
		State.HURT:
			hurt_behavior(delta)
	
	move_and_slide()
	_handle_collisions()

# ███  SISTEMA DE DANO  ███
func take_damage(amount: int):
	if is_dead or current_state == State.DEAD or not is_instance_valid(self):
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	print("🦇 Morcego tomou ", amount, " de dano! Vida: ", current_health)
	
	if current_health > 0:
		current_state = State.HURT
		if animation_player and animation_player.has_animation("hurt"):
			animation_player.play("hurt")
		else:
			print("💢 Morcego ferido!")
		
		# Volta para o estado anterior depois do hurt
		await get_tree().create_timer(0.5).timeout
		if is_dead or not is_instance_valid(self):
			return
		if player_ref and is_instance_valid(player_ref):
			current_state = State.CHASE
		else:
			current_state = State.PATROL
	else:
		die()

func hurt_behavior(_delta: float):
	# Comportamento durante o estado de hurt
	velocity.x = lerp(velocity.x, 0.0, 0.1)
	velocity.y = lerp(velocity.y, 0.0, 0.1)

func die():
	is_dead = true
	current_state = State.DEAD
	print("💀 Morcego morreu!")
	
	# Para completamente
	velocity = Vector2.ZERO
	
	# Toca animação de morte
	if animation_player and is_instance_valid(animation_player):
		if animation_player.has_animation("dead"):
			animation_player.play("dead")
		elif animation_player.has_animation("death"):
			animation_player.play("death")
		else:
			# Se não tiver animação, usa fallback
			await get_tree().create_timer(0.5).timeout
			if is_instance_valid(self):
				queue_free()
	
	# Desativa colisões
	set_collision_layer_value(3, false)  # enemies layer
	set_collision_mask_value(2, false)   # world layer
	
	# Desativa áreas
	if detection_area and is_instance_valid(detection_area):
		detection_area.monitoring = false
	if hurtbox and is_instance_valid(hurtbox):
		hurtbox.monitoring = false
	
	# Espera a animação terminar antes de remover
	if animation_player and is_instance_valid(animation_player) and (animation_player.has_animation("dead") or animation_player.has_animation("death")):
		await animation_player.animation_finished
		if is_instance_valid(self):
			queue_free()
	else:
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self):
			queue_free()

# ███  DETECÇÃO DE DANO  ███
func _on_hurtbox_body_entered(body: Node2D):
	if is_dead or current_state == State.DEAD:
		return
	
	# Verifica se foi atingido por um ataque do player
	if body.is_in_group("player_weapon") or body.is_in_group("player_attack"):
		print("⚔️ Morcego atingido por ataque!")
		take_damage(1)  # Reduzido para 1 de dano para equilibrar
	
	# Ou se colidiu com o player (dano por contato)
	elif body.is_in_group("player") and body.has_method("take_damage"):
		print("👊 Dano por contato com player!")
		take_damage(1)  # Reduzido para 1 de dano

# ███  COMPORTAMENTOS  ███
func patrol_behavior(delta: float) -> void:
	if is_dead or current_state != State.PATROL:
		return
		
	global_position.y = lerp(global_position.y, original_y, delta * 2.0)
	
	wall_detector.target_position.x = MIN_DISTANCE_FROM_WALL * direction
	if wall_detector.is_colliding():
		invert_direction()

	random_timer += delta
	if random_timer >= random_time:
		invert_direction()
		random_timer = 0.0
		random_time = 1.5 + randf() * 3.0

	velocity.x = direction * SPEED
	velocity.y = 0

	if animation_player and animation_player.has_animation("fly"):
		animation_player.play("fly")

func chase_behavior(delta: float) -> void:
	if is_dead or current_state != State.CHASE or not is_instance_valid(player_ref):
		return

	var dx = player_ref.global_position.x - global_position.x
	var dy = player_ref.global_position.y - global_position.y

	wall_detector.target_position.x = MIN_DISTANCE_FROM_WALL * direction
	if wall_detector.is_colliding():
		# Evasão de paredes
		velocity.y = -CHASE_SPEED * 0.8
		velocity.x = 0
		if animation_player and animation_player.has_animation("fly"):
			animation_player.play("fly")
		return

	# Distância mínima do player para evitar grudar
	var distance_to_player = global_position.distance_to(player_ref.global_position)
	if distance_to_player < 20:  # Muito perto - recua
		velocity.x = -direction * SPEED * 0.5
		velocity.y = sign(dy) * CHASE_SPEED * 0.3
	else:
		# Persegue normalmente
		if abs(dx) > 15:  # Aumentada a distância mínima
			direction = sign(dx)
			velocity.x = direction * CHASE_SPEED
		else:
			velocity.x = 0

		velocity.y = clamp(sign(dy) * CHASE_SPEED * 0.4, -50, 50)

	texture.flip_h = (direction == 1)
	
	if animation_player and animation_player.has_animation("fly"):
		animation_player.play("fly")

# ███  OUTRAS FUNÇÕES  ███
func _handle_collisions():
	if is_dead or current_state == State.DEAD:
		return
		
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		if collision:
			_avoid_collision(collision.get_normal())

func _avoid_collision(collision_normal: Vector2):
	if abs(collision_normal.x) > abs(collision_normal.y):
		invert_direction()
		velocity.y = -CHASE_SPEED * 0.5 if randf() > 0.5 else CHASE_SPEED * 0.5

func invert_direction():
	direction *= -1
	texture.flip_h = (direction == 1)

# ███  DETECÇÃO DO PLAYER  ███
func _on_detection_area_body_entered(body: Node2D):
	if is_dead or current_state == State.DEAD:
		return
		
	if body.is_in_group("player") and body is CharacterBody2D:
		player_ref = body
		current_state = State.CHASE
		print("🔍 Morcego detectou o player!")

func _on_detection_area_body_exited(body: Node2D):
	if body == player_ref:
		player_ref = null
		current_state = State.PATROL
		print("👋 Player saiu da detecção")
