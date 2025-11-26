extends CharacterBody2D

const SPEED = 50.0
const CHASE_SPEED = 80.0
const GRAVITY = 980.0

# 🔥 CORRIGIDO: Nomes dos nós conforme sua cena
@onready var wall_detector := $wall_detector as RayCast2D
@onready var texture := $texture as Sprite2D
@onready var detection_area := $DetectionArea as Area2D
@onready var attack_area := $attack1 as Area2D  # 🔥 Nome correto da cena
@onready var animation_player := $anim as AnimationPlayer
@onready var hurtbox := $hitbox as Area2D  # 🔥 Adicionado hurtbox

# 🔴 SISTEMA DE VIDA
@export var max_health: int = 100
var current_health: int = max_health
var is_dead: bool = false

# 🎯 SISTEMA DE ATAQUE
@export var attack_damage: int = 20
var can_attack: bool = true
var attack_cooldown: float = 2.0
var is_attacking: bool = false

var direction := 1
var can_detect := true
var detection_cooldown := 0.5
var last_direction := 1  # 🔥 Para evitar spam

# Estados do golem
enum State { PATROL, CHASE, ATTACK, HURT, DEAD }
var current_state = State.PATROL
var player_ref: CharacterBody2D = null

func _ready():
	# Adiciona ao grupo enemy
	add_to_group("enemy")
	
	# Conecta os sinais das áreas
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)  # 🔥 Conecta hurtbox
	
	# Conecta o sinal de animação terminada
	if animation_player and animation_player.has_signal("animation_finished"):
		animation_player.animation_finished.connect(_on_animation_finished)
	
	# Configura posição inicial da área de ataque
	update_attack_area_position()
	
	# Configura collision layers e masks
	setup_collision_layers()
	
	current_health = max_health
	print("🪨 Golem inicializado - Vida: ", current_health)

# 🔥 CONFIGURAÇÃO DAS LAYERS E MASKS
func setup_collision_layers():
	# Corpo principal do Golem
	set_collision_layer_value(3, true)  # enemies
	set_collision_mask_value(2, true)   # world
	
	# DetectionArea (detecta player)
	detection_area.set_collision_layer_value(3, true)  # enemies
	detection_area.set_collision_mask_value(1, true)   # player
	
	# AttackArea (hitbox - causa dano)
	attack_area.set_collision_layer_value(5, true)     # hitbox
	attack_area.set_collision_mask_value(6, true)      # hurtbox (player)
	
	# Hurtbox (recebe dano)
	hurtbox.set_collision_layer_value(6, true)         # hurtbox
	hurtbox.set_collision_mask_value(5, true)          # hitbox (player)

# 🔥 FUNÇÃO PARA ATUALIZAR POSIÇÃO DA ÁREA DE ATAQUE (SEM SPAM)
func update_attack_area_position():
	if attack_area and is_instance_valid(attack_area):
		if texture.flip_h:  # Virado para esquerda
			attack_area.position = Vector2(-40, 0)
		else:  # Virado para direita
			attack_area.position = Vector2(40, 0)
		# print("🎯 AttackArea posicionada: ", attack_area.position)  # 🔥 Comentado para evitar spam

func _physics_process(delta: float) -> void:
	if is_dead or current_state == State.DEAD or not is_instance_valid(self):
		return
	
	# Gravidade
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Máquina de estados
	match current_state:
		State.PATROL:
			patrol_behavior(delta)
		State.CHASE:
			chase_behavior(delta)
		State.ATTACK:
			attack_behavior(delta)
		State.HURT:
			hurt_behavior(delta)
	
	move_and_slide()

func patrol_behavior(_delta: float):
	# Inverte o raycast
	wall_detector.scale.x = direction
	
	# Detecção de paredes com cooldown
	if can_detect and wall_detector.is_colliding():
		print("🔄 Golem virando...")
		direction *= -1
		can_detect = false
		start_cooldown()
	
	# Atualiza sprite
	texture.flip_h = (direction == -1)
	
	# 🔥 ATUALIZA ÁREA DE ATAQUE APENAS SE DIREÇÃO MUDOU
	if last_direction != direction:
		update_attack_area_position()
		last_direction = direction
	
	# Movimento
	velocity.x = direction * SPEED
	
	# Animação
	if animation_player and is_instance_valid(animation_player):
		animation_player.play("walk")

func chase_behavior(_delta: float):
	if player_ref and is_instance_valid(player_ref):
		# Calcula direção até o player
		var player_direction = sign(player_ref.global_position.x - global_position.x)
		
		# Atualiza direção e sprite
		direction = player_direction
		texture.flip_h = (direction == -1)
		
		# 🔥 ATUALIZA ÁREA DE ATAQUE APENAS SE DIREÇÃO MUDOU
		if last_direction != direction:
			update_attack_area_position()
			last_direction = direction
		
		# Movimento
		velocity.x = direction * CHASE_SPEED
		
		# Verifica se está perto o suficiente para atacar
		var distance_to_player = abs(player_ref.global_position.x - global_position.x)
		if distance_to_player < 80 and can_attack and not is_attacking:
			current_state = State.ATTACK
			print("🎯 Golem iniciando ataque!")
		
		# Animação
		if animation_player and is_instance_valid(animation_player):
			if animation_player.has_animation("run"):
				animation_player.play("run")
			else:
				animation_player.play("walk")
	else:
		# Volta para patrulha se perdeu o player
		current_state = State.PATROL
		print("👋 Golem perdeu o player, voltando à patrulha")

func attack_behavior(_delta: float):
	# Para o movimento durante o ataque
	velocity.x = 0
	
	if can_attack and not is_attacking and not is_dead:
		is_attacking = true
		print("💥 Golem atacando!")
		
		# Toca animação de ataque
		if animation_player and is_instance_valid(animation_player):
			if animation_player.has_animation("hit"):
				animation_player.play("hit")
			elif animation_player.has_animation("hit"):
				animation_player.play("hit")
		
		# Pequeno delay antes do ataque - COM VERIFICAÇÃO
		await get_tree().create_timer(0.3).timeout
		if is_dead or not is_instance_valid(self):
			return
		
		# Ativa a área de ataque
		if attack_area and is_instance_valid(attack_area):
			attack_area.monitoring = true
			print("✅ AttackArea ativada")
		
		# Aguarda o ataque acontecer - COM VERIFICAÇÃO
		await get_tree().create_timer(0.2).timeout
		if is_dead or not is_instance_valid(self):
			return
		
		# Desativa a área de ataque
		if attack_area and is_instance_valid(attack_area):
			attack_area.monitoring = false
			print("❌ AttackArea desativada")
		
		# Cooldown do ataque - COM VERIFICAÇÃO
		can_attack = false
		await get_tree().create_timer(attack_cooldown).timeout
		if is_dead or not is_instance_valid(self):
			return
		
		can_attack = true
		is_attacking = false
		
		# Volta para perseguição ou patrulha
		if player_ref and is_instance_valid(player_ref):
			current_state = State.CHASE
			print("🔁 Voltando para perseguição")
		else:
			current_state = State.PATROL
			print("🔁 Voltando para patrulha")

func hurt_behavior(_delta: float):
	# Para o movimento durante o hurt
	velocity.x = 0

# Sinal de animação terminada
func _on_animation_finished(anim_name: String):
	if anim_name == "attack" or anim_name == "hit":
		print("✅ Animação de ataque terminou")
		is_attacking = false
	elif anim_name == "hurt":
		print("✅ Animação de hurt terminou")
		# Volta para o estado anterior depois do hurt
		if player_ref and is_instance_valid(player_ref):
			current_state = State.CHASE
		else:
			current_state = State.PATROL

# ⏰ FUNÇÃO DO COOLDOWN
func start_cooldown():
	await get_tree().create_timer(detection_cooldown).timeout
	if not is_dead and is_instance_valid(self):
		can_detect = true

# 🎯 DETECÇÃO DO PLAYER
func _on_detection_area_body_entered(body: Node2D):
	if body.is_in_group("player") and body is CharacterBody2D and not is_dead:
		print("🔍 Golem detectou o player!")
		player_ref = body
		current_state = State.CHASE

func _on_detection_area_body_exited(body: Node2D):
	if body == player_ref and not is_dead:
		print("👋 Player saiu da área de detecção")
		player_ref = null
		current_state = State.PATROL

# 💥 ATAQUE AO PLAYER
func _on_attack_area_body_entered(body: Node2D):
	if body.is_in_group("player") and body.has_method("take_damage") and not is_dead:
		print("💢 Golem causou ", attack_damage, " de dano ao player!")
		body.take_damage(attack_damage)

# 🔥 RECEBER DANO DO PLAYER (via hurtbox)
func _on_hurtbox_area_entered(area: Area2D):
	if area.is_in_group("player_attack") and area.has_method("get_damage") and not is_dead:
		var damage = area.get_damage()
		take_damage(damage)

# 🔴 SISTEMA DE VIDA DO GOLEM
func take_damage(amount: int):
	if is_dead or current_state == State.DEAD or not is_instance_valid(self):
		return
	
	current_health -= amount
	current_health = max(0, current_health)
	print("🪨 Golem tomou ", amount, " de dano! Vida: ", current_health)
	
	if current_health > 0:
		current_state = State.HURT
		if animation_player and animation_player.has_animation("hurt"):
			animation_player.play("hurt")
		else:
			print("💢 Golem ferido!")
		
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

func die():
	is_dead = true
	current_state = State.DEAD
	print("💀 Golem morreu!")
	
	# Cancela qualquer ataque em andamento
	is_attacking = false
	can_attack = false
	
	# Toca animação de morte
	if animation_player and is_instance_valid(animation_player):
		if animation_player.has_animation("dead"):
			animation_player.play("dead")
		elif animation_player.has_animation("death"):
			animation_player.play("death")
		else:
			await get_tree().create_timer(1.0).timeout
			if is_instance_valid(self):
				queue_free()
	
	# Desativa colisões
	set_collision_layer_value(3, false)  # enemies
	set_collision_mask_value(2, false)   # world
	
	# Desativa áreas
	if detection_area and is_instance_valid(detection_area):
		detection_area.monitoring = false
	if attack_area and is_instance_valid(attack_area):
		attack_area.monitoring = false
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
