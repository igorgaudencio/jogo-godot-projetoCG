extends CharacterBody2D

# ===============================
# 🔹 VARIÁVEIS DE VIDA
# ===============================
@export var max_health: int = 100          # Vida máxima do player
var current_health: int = max_health       # Vida atual
var is_dead: bool = false                  # Flag de morte

signal health_changed(value)               # Emite sinal quando a vida muda

# ===============================
# 🔹 MOVIMENTO E FÍSICA
# ===============================
@export var speed: float = 150.0           # Velocidade normal
@export var jump_force: float = -400.0     # Força do pulo
@export var gravity: float = 900.0         # Gravidade aplicada

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# ===============================
# 🔹 DASH CONFIGURAÇÃO
# ===============================
@export var dash_speed: float = 450.0      # Velocidade durante o dash
@export var dash_duration: float = 0.2     # Tempo que o dash dura
@export var dash_clicks_required: int = 2  # Quantos cliques para ativar o dash
@export var dash_click_time: float = 0.4   # Tempo máximo entre cliques

@export var dash_cooldown: float = 1.5     # ⏳ COOLDOWN do dash (delay que você pediu)
var dash_cooldown_left: float = 0.0        # Tempo restante até poder dar dash novamente

var dash_timer: float = 0.0                # Timer para contar cliques rápidos
var dash_direction: int = 0                # Direção do dash (-1 esquerda / 1 direita)
var click_count_left: int = 0              # Quantidade de cliques na esquerda
var click_count_right: int = 0             # Quantidade de cliques na direita
var dash_time_left: float = 0.0            # Tempo restante no dash ativo
var is_dashing: bool = false               # Flag do dash ativo

# ===============================
# 🔹 ATAQUE
# ===============================
var is_attacking: bool = false
@export var attack_duration: float = 0.3   # Tempo da animação do ataque

# ===============================
# 🔹 TOMAR DANO
# ===============================
func take_damage(amount: int):
	if is_dead:
		return

	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	print("❤️ Vida atual:", current_health)
	emit_signal("health_changed", current_health)

	if current_health <= 0:
		die()

# ===============================
# 🔹 MORTE
# ===============================
func die():
	is_dead = true
	current_health = 0
	print("💀 Player morreu!")
	get_tree().reload_current_scene()

# ===============================
# 🔹 PROCESSAMENTO PRINCIPAL
# ===============================
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Aplica gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# Atualiza cooldown do dash
	if dash_cooldown_left > 0:
		dash_cooldown_left -= delta

	# ==========================
	# DASH LÓGICA
	# ==========================
	if is_dashing:
		# Enquanto estiver dashando
		dash_time_left -= delta
		if dash_time_left > 0:
			velocity.x = dash_direction * dash_speed
		else:
			is_dashing = false
	else:
		# Movimento normal
		var direction := Input.get_axis("ui_left", "ui_right")
		velocity.x = direction * speed

		# Detecta cliques para dash
		if Input.is_action_just_pressed("ui_left"):
			_handle_dash_input(-1)
		elif Input.is_action_just_pressed("ui_right"):
			_handle_dash_input(1)

	# ==========================
	# PULO
	# ==========================
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_force

	# ==========================
	# ATAQUE
	# ==========================
	if Input.is_action_just_pressed("mouse_right") and not is_attacking:
		attack()

	# ==========================
	# ANIMAÇÕES
	# ==========================
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

	# Espelha o sprite conforme direção
	if velocity.x != 0:
		anim.flip_h = velocity.x < 0

	move_and_slide()

# ===============================
# 🔹 TRATAMENTO DO CLIQUE DE DASH
# ===============================
func _handle_dash_input(direction: int):

	# ❌ NÃO deixa iniciar dash se estiver em cooldown
	print(dash_cooldown_left)
	if dash_cooldown_left > 0:
		return

	# Contabiliza cliques de acordo com a direção
	if direction == -1:
		click_count_left += 1
		click_count_right = 0
		_start_dash_timer("left")
	elif direction == 1:
		click_count_right += 1
		click_count_left = 0
		_start_dash_timer("right")

# ===============================
# 🔹 INÍCIO DA CONTAGEM ENTRE CLICKS
# ===============================
func _start_dash_timer(side: String):
	# Reinicia o tempo limite entre cliques
	dash_timer = dash_click_time

	# Se atingiu o número de cliques requeridos → ativa dash
	if side == "left" and click_count_left >= dash_clicks_required:
		_start_dash(-1)
		click_count_left = 0

	elif side == "right" and click_count_right >= dash_clicks_required:
		_start_dash(1)
		click_count_right = 0

# ===============================
# 🔹 CONTADOR DO TEMPO ENTRE CLICKS
# ===============================
func _process(delta: float) -> void:
	# Se o tempo entre cliques acabar → reset
	if dash_timer > 0:
		dash_timer -= delta
	else:
		click_count_left = 0
		click_count_right = 0

# ===============================
# 🔹 INICIAR DASH
# ===============================
func _start_dash(direction: int):
	is_dashing = true
	dash_direction = direction
	dash_time_left = dash_duration

	# Ativa cooldown do dash
	dash_cooldown_left = dash_cooldown

	print("⚡ Dash ativado para direção:", direction)

# ===============================
# 🔹 ATAQUE
# ===============================
func attack():
	is_attacking = true
	print("👊 Ataque iniciado!")
	await get_tree().create_timer(attack_duration).timeout
	is_attacking = false
