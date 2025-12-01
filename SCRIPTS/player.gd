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
# 🔹 SISTEMA DE ATAQUE - REVISADO
# ===============================
@export var attack_damage: int = 20
@onready var attack_area := $AttackArea as Area2D
@onready var hitbox := $hitbox as Area2D

# 🔥 NOVO: Controle mais rigoroso de ataque
var attack_cooldown_timer: float = 0.0
var attack_active: bool = false

# Sinal emitido quando a vida muda
signal health_changed(value)

# ===============================
# 🔹 MOVIMENTO E FÍSICA
# ===============================
@export var speed: float = 250.0
@export var jump_force: float = -460.0
@export var gravity: float = 900.0

# Referência ao AnimatedSprite2D
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
# 🔹 ATAQUE SIMPLES - REVISADO
# ===============================
var is_attacking: bool = false
var can_attack: bool = true

# ===============================
# 🔹 INTERAÇÃO COM PORTAS
# ===============================
var pode_entrar: bool = false

# ===============================
# 🔹 INICIALIZAÇÃO
# ===============================

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	emit_signal("health_changed", current_health)
	
	# 🔥 CORREÇÃO COMPLETA: Configurar áreas corretamente
	setup_attack_area()
	
	if hitbox:
		hitbox.area_entered.connect(_on_hitbox_area_entered)
	
	setup_collision_layers()
	print("✅ Player inicializado - AttackArea desativada")

# 🔥 FUNÇÃO ESPECÍFICA PARA CONFIGURAR A ÁREA DE ATAQUE
func setup_attack_area():
	if attack_area:
		# 🔥 DESATIVAR COMPLETAMENTE
		attack_area.monitoring = false
		attack_area.monitorable = false
		attack_area.set_deferred("monitoring", false)
		attack_area.set_deferred("monitorable", false)
		
		# 🔥 CONECTAR SINAL APENAS UMA VEZ
		if not attack_area.body_entered.is_connected(_on_attack_area_body_entered):
			attack_area.body_entered.connect(_on_attack_area_body_entered)

func setup_collision_layers():
	set_collision_layer_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(3, true)
	
	if attack_area:
		attack_area.set_collision_layer_value(5, true)
		attack_area.set_collision_mask_value(6, true)
		attack_area.add_to_group("player_attack")
	
	if hitbox:
		hitbox.set_collision_layer_value(6, true)
		hitbox.set_collision_mask_value(5, true)

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
	get_tree().change_scene_to_file("res://CENAS/game_over.tscn")

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
	# ATAQUE SIMPLES - REVISADO
	# ==========================
	if Input.is_action_just_pressed("attack") and not is_attacking and not is_taking_damage and can_attack:
		attack()
		hit.play()

	# ==========================
	# ANIMAÇÕES
	# ==========================
	update_animations()

	if velocity.x != 0 and not is_taking_damage:
		anim.flip_h = velocity.x < 0
		update_attack_area_position()

	move_and_slide()

# ===============================
# 🔹 TROCA DE CENA COM UI_INTERACT
# ===============================
func _input(event):
	if event.is_action_pressed("ui_interact") and pode_entrar:
		get_tree().change_scene_to_file("res://CENAS/cutscene02.tscn")
		print("Trocando para Cena02")

# ===============================
# 🔹 FUNÇÕES DE INTERAÇÃO
# ===============================
func set_pode_entrar(valor: bool):
	pode_entrar = valor
	print("Pode entrar: ", valor)

func update_attack_area_position():
	if attack_area and is_instance_valid(attack_area):
		if anim.flip_h:
			attack_area.position = Vector2(-15, 0)
		else:
			attack_area.position = Vector2(15, 0)

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
# 🔹 ATAQUE SIMPLES - SISTEMA REVISADO
# ===============================

func attack():
	is_attacking = true
	can_attack = false
	attack_active = true
	
	print("⚔️ Player atacando!")
	
	anim.play("attack")
	
	# 🔥 ATIVAR ÁREA DE ATAQUE COM SEGURANÇA
	await get_tree().create_timer(0.3).timeout  # Pequeno delay antes do dano
	
	if attack_area and is_instance_valid(attack_area) and not is_dead:
		# 🔥 ATIVAR MONITORING E MONITORABLE
		attack_area.monitoring = true
		attack_area.monitorable = true
		print("✅ AttackArea ATIVADA - Pode causar dano")
	
	# Manter área ativa por um curto período
	await get_tree().create_timer(0.15).timeout
	
	# 🔥 DESATIVAR COMPLETAMENTE APÓS O ATAQUE
	if attack_area and is_instance_valid(attack_area):
		attack_area.monitoring = false
		attack_area.monitorable = false
		attack_active = false
		print("❌ AttackArea DESATIVADA - Não causa mais dano")
	
	# Finalizar ataque
	is_attacking = false
	
	# Cooldown do ataque
	await get_tree().create_timer(0.2).timeout
	can_attack = true

func _on_attack_area_body_entered(body: Node2D):
	# 🔥 VERIFICAÇÃO EXTRA DE SEGURANÇA
	if not attack_active:
		print("🚫 AttackArea detectou colisão mas está INATIVA - Ignorando")
		return
		
	if body.is_in_group("enemy") and body.has_method("take_damage") and not is_dead:
		print("💢 Player causou ", attack_damage, " de dano ao inimigo!")
		body.take_damage(attack_damage)
		
		# 🔥 OPIONAL: Desativar após acertar um inimigo
		attack_active = false
		if attack_area and is_instance_valid(attack_area):
			attack_area.monitoring = false
			attack_area.monitorable = false

func _on_hitbox_area_entered(area: Area2D):
	if area.is_in_group("enemy_attack") and not is_dead:
		var damage = 10
		if area.has_method("get_damage"):
			damage = area.get_damage()
		take_damage(damage)
		
		
