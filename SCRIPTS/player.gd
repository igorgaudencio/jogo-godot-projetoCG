extends CharacterBody2D

# ===============================
# 🔹 VARIÁVEIS DE SOM
# ===============================
@onready var hit = $hit as AudioStreamPlayer


# ===============================
# 🔹 VARIÁVEIS DE VIDA
# ===============================
@export var max_health: int = 100
var current_health: int = max_health
var is_dead: bool = false
var is_taking_damage: bool = false

# ===============================
# 🔹 SISTEMA DE ATAQUE (CORRIGIDO!)
# ===============================
@export var attack_damage: int = 20
@onready var attack_area := $AttackArea as Area2D  # 🔥 CAUSA DANO
@onready var hitbox := $hitbox as Area2D           # 🔥 RECEBE DANO 

# Sinal emitido quando a vida muda (para atualizar o HUD)
signal health_changed(value)

# ===============================
# 🔹 MOVIMENTO E FÍSICA
# ===============================
@export var speed: float = 250.0
@export var jump_force: float = -460.0
@export var gravity: float = 900.0

# Referência ao AnimatedSprite2D para controlar animações
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# ===============================
# 🔹 DASH CONFIGURAÇÃO
# ===============================
@export var dash_speed: float = 450.0
@export var dash_duration: float = 0.2
@export var dash_clicks_required: int = 2
@export var dash_click_time: float = 0.4

# Variáveis de controle do dash
var dash_timer: float = 0.0
var dash_direction: int = 0
var click_count_left: int = 0
var click_count_right: int = 0
var dash_time_left: float = 0.0
var is_dashing: bool = false

# ===============================
# 🔹 ATAQUE SIMPLES
# ===============================
var is_attacking: bool = false
var can_attack: bool = true

# ===============================
# 🔹 INICIALIZAÇÃO
# ===============================

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	emit_signal("health_changed", current_health)
	
	# 🔥 CONECTAR SINAIS DAS ÁREAS (CORRIGIDO!)
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)  # 🔥 CORRIGIDO!
	
	# 🔥 CONFIGURAR LAYERS (CORRIGIDO!)
	setup_collision_layers()

# 🔥 CONFIGURAR LAYERS (CORRIGIDA!)
func setup_collision_layers():
	# Corpo do Player
	set_collision_layer_value(1, true)  # player
	set_collision_mask_value(2, true)   # world
	set_collision_mask_value(3, true)   # enemies
	
	# AttackArea (CAUSA dano)
	if attack_area:
		attack_area.set_collision_layer_value(5, true)  # hitbox layer
		attack_area.set_collision_mask_value(6, true)   # hitbox mask (inimigos)
		attack_area.add_to_group("player_attack")
	
	# Hitbox (RECEBE dano) - 🔥 CORRIGIDO!
	if hitbox:
		hitbox.set_collision_layer_value(6, true)      # hitbox layer  
		hitbox.set_collision_mask_value(5, true)       # hitbox mask (inimigos)

# ===============================
# 🔹 DANO E MORTE
# ===============================

func take_damage(amount: int):
	if is_dead or is_taking_damage:
		return

	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	
	is_taking_damage = true
	anim.play("hurt")
	
	await get_tree().create_timer(0.5).timeout
	is_taking_damage = false
	
	emit_signal("health_changed", current_health)

	if current_health <= 0:
		die()

func die():
	is_dead = true
	current_health = 0
	emit_signal("health_changed", current_health)
	anim.play("hurt")
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

# ===============================
# 🔹 PROCESSAMENTO PRINCIPAL
# ===============================

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = 0
		move_and_slide()
		return

	# ==========================
	# ATUALIZA TIMER DO DASH
	# ==========================
	if dash_timer > 0:
		dash_timer -= delta
	else:
		click_count_left = 0
		click_count_right = 0

	# ==========================
	# GRAVIDADE
	# ==========================
	if not is_on_floor():
		velocity.y += gravity * delta

	# ==========================
	# DASH LÓGICA
	# ==========================
	if is_dashing:
		dash_time_left -= delta
		if dash_time_left > 0:
			velocity.x = dash_direction * dash_speed
		else:
			is_dashing = false
	else:
		var direction := Input.get_axis("ui_left", "ui_right")
		velocity.x = direction * speed 

		if Input.is_action_just_pressed("ui_left"):
			_handle_dash_input(-1)
		elif Input.is_action_just_pressed("ui_right"):
			_handle_dash_input(1)

	# ==========================
	# PULO
	# ==========================
	if Input.is_action_just_pressed("ui_up") and is_on_floor() and not is_taking_damage:
		velocity.y = jump_force
		

	# ==========================
	# ATAQUE SIMPLES
	# ==========================
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_taking_damage and can_attack:
		attack()
		hit.play()

	# ==========================
	# ANIMAÇÕES
	# ==========================
	update_animations()

	# Espelhar sprite
	if velocity.x != 0 and not is_taking_damage:
		anim.flip_h = velocity.x < 0
		
		# 🔥 ATUALIZAR POSIÇÃO DA ÁREA DE ATAQUE
		update_attack_area_position()

	move_and_slide()

# 🔥 ATUALIZAR POSIÇÃO DA ÁREA DE ATAQUE
func update_attack_area_position():
	if attack_area and is_instance_valid(attack_area):
		if anim.flip_h:  # Virado para esquerda
			attack_area.position = Vector2(-30, 0)
		else:  # Virado para direita
			attack_area.position = Vector2(30, 0)

# Função separada para lidar com animações
func update_animations():
	if is_taking_damage:
		return
	
	if is_attacking:
		anim.play("attack")
	elif is_dashing:
		anim.play("dash")
	elif not is_on_floor():
		anim.play("jump")
	elif velocity.x == 0:
		anim.play("idle")
	else:
		anim.play("run")

# ===============================
# 🔹 DASH HANDLER
# ===============================

func _handle_dash_input(direction: int):
	if is_taking_damage:
		return
		
	if direction == -1:
		click_count_left += 1
		click_count_right = 0
		_start_dash_timer("left")
	elif direction == 1:
		click_count_right += 1
		click_count_left = 0
		_start_dash_timer("right")

func _start_dash_timer(side: String):
	if dash_timer == 0:
		dash_timer = dash_click_time
	else:
		dash_timer = dash_click_time

	if side == "left" and click_count_left >= dash_clicks_required:
		_start_dash(-1)
		click_count_left = 0
	elif side == "right" and click_count_right >= dash_clicks_required:
		_start_dash(1)
		click_count_right = 0

func _start_dash(direction: int):
	is_dashing = true
	dash_direction = direction
	dash_time_left = dash_duration

# ===============================
# 🔹 ATAQUE SIMPLES
# ===============================

func attack():
	is_attacking = true
	can_attack = false
	print("⚔️ Player atacando!")
	
	anim.play("attack")
	
	# 🔥 ATIVAR ÁREA DE ATAQUE
	if attack_area and is_instance_valid(attack_area):
		attack_area.monitoring = true
		print("✅ Player AttackArea ativada")
	
	# Espera a animação terminar
	await get_tree().create_timer(0.3).timeout
	
	# 🔥 DESATIVAR ÁREA DE ATAQUE
	if attack_area and is_instance_valid(attack_area):
		attack_area.monitoring = false
		print("❌ Player AttackArea desativada")
	
	is_attacking = false
	
	# Cooldown do ataque
	await get_tree().create_timer(0.2).timeout
	can_attack = true

# 🔥 SINAL DE ATAQUE ACERTOU INIMIGO
func _on_attack_area_body_entered(body: Node2D):
	if body.is_in_group("enemy") and body.has_method("take_damage") and not is_dead:
		print("💢 Player causou ", attack_damage, " de dano ao inimigo!")
		body.take_damage(attack_damage)

# 🔥 SINAL DE RECEBER DANO (CORRIGIDO!)
func _on_hitbox_area_entered(area: Area2D):  # 🔥 NOME CORRIGIDO!
	if area.is_in_group("enemy_attack") and not is_dead:
		var damage = 10  # Dano padrão
		if area.has_method("get_damage"):
			damage = area.get_damage()
		take_damage(damage)
