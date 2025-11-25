extends CharacterBody2D

# ===============================
# 🔹 VARIÁVEIS DE VIDA
# ===============================
@export var max_health: int = 100  # Vida máxima do jogador (exportada para editar no inspector)
var current_health: int = max_health  # Vida atual do jogador
var is_dead: bool = false  # Flag para verificar se o jogador está morto

# Sinal emitido quando a vida muda (para atualizar o HUD)
signal health_changed(value)

# ===============================
# 🔹 MOVIMENTO E FÍSICA
# ===============================
@export var speed: float = 150.0  # Velocidade de movimento horizontal
@export var jump_force: float = -400.0  # Força do pulo (negativo porque Y cresce para baixo)
@export var gravity: float = 900.0  # Força da gravidade aplicada ao jogador

# Referência ao AnimatedSprite2D para controlar animações
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# ===============================
# 🔹 DASH CONFIGURAÇÃO
# ===============================
@export var dash_speed: float = 450.0  # Velocidade durante o dash
@export var dash_duration: float = 0.2  # Quanto tempo o dash dura
@export var dash_clicks_required: int = 2  # Quantos cliques são necessários para ativar o dash
@export var dash_click_time: float = 0.4  # Tempo máximo entre cliques para contar como duplo clique

# Variáveis de controle do dash
var dash_timer: float = 0.0  # Timer para contar tempo entre cliques
var dash_direction: int = 0  # Direção do dash (-1 esquerda, 1 direita)
var click_count_left: int = 0  # Contador de cliques para esquerda
var click_count_right: int = 0  # Contador de cliques para direita
var dash_time_left: float = 0.0  # Tempo restante do dash atual
var is_dashing: bool = false  # Flag para verificar se está dando dash

# ===============================
# 🔹 ATAQUE
# ===============================
var is_attacking: bool = false  # Flag para verificar se está atacando
@export var attack_duration: float = 0.3  # Duração da animação de ataque

# ===============================
# 🔹 DANO E MORTE
# ===============================

# Função chamada quando o jogador recebe dano
func take_damage(amount: int):
	# Se já está morto, ignora o dano
	if is_dead:
		return

	# Reduz a vida atual
	current_health -= amount
	# Garante que a vida fique entre 0 e max_health
	current_health = clamp(current_health, 0, max_health)
	print("❤️ Vida atual:", current_health)
	
	# Emite sinal para atualizar o HUD
	emit_signal("health_changed", current_health)

	# Verifica se morreu
	if current_health <= 0:
		die()

# Função chamada quando o jogador morre
func die():
	is_dead = true  # Marca como morto
	current_health = 0  # Garante que a vida seja 0
	print("💀 Player morreu!")
	# Recarrega a cena atual (reinicia o nível)
	get_tree().reload_current_scene()

# ===============================
# 🔹 PROCESSAMENTO PRINCIPAL
# ===============================

# Função chamada a cada frame para física e movimento
func _physics_process(delta: float) -> void:
	# Se está morto, não processa movimento
	if is_dead:
		return

	# ==========================
	# GRAVIDADE
	# ==========================
	# Aplica gravidade apenas se não estiver no chão
	if not is_on_floor():
		velocity.y += gravity * delta

	# ==========================
	# DASH LÓGICA
	# ==========================
	if is_dashing:
		# Durante o dash, mantém a velocidade horizontal constante
		dash_time_left -= delta
		if dash_time_left > 0:
			velocity.x = dash_direction * dash_speed
		else:
			# Termina o dash quando o tempo acaba
			is_dashing = false
	else:
		# Movimento normal quando não está dando dash
		# Input.get_axis retorna -1 (esquerda), 0 (nenhum), ou 1 (direita)
		var direction := Input.get_axis("ui_left", "ui_right")
		velocity.x = direction * speed

		# Verifica cliques para dash
		if Input.is_action_just_pressed("ui_left"):
			_handle_dash_input(-1)
		elif Input.is_action_just_pressed("ui_right"):
			_handle_dash_input(1)

	# ==========================
	# PULO
	# ==========================
	# Pula apenas se pressionou "ui_up" e está no chão
	if Input.is_action_just_pressed("ui_up") and is_on_floor():
		velocity.y = jump_force

	# ==========================
	# ATAQUE
	# ==========================
	# Ataca se pressionou botão direito do mouse e não está já atacando
	if Input.is_action_just_pressed("mouse_right") and not is_attacking:
		attack()

	# ==========================
	# ANIMAÇÕES
	# ==========================
	# Prioridade das animações: ataque > dash > pulo > idle/run
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

	# Espelhar sprite horizontalmente baseado na direção do movimento
	if velocity.x != 0:
		anim.flip_h = velocity.x < 0  # True se movendo para esquerda

	# Aplica o movimento e lida com colisões
	move_and_slide()

# ===============================
# 🔹 DASH HANDLER
# ===============================

# Processa entrada para o sistema de dash
func _handle_dash_input(direction: int):
	# Incrementa contador baseado na direção
	if direction == -1:
		click_count_left += 1
		click_count_right = 0  # Zera contador da direção oposta
		_start_dash_timer("left")
	elif direction == 1:
		click_count_right += 1
		click_count_left = 0  # Zera contador da direção oposta
		_start_dash_timer("right")

# Inicia ou reinicia o timer para contagem de cliques
func _start_dash_timer(side: String):
	# Se é o primeiro clique, inicia o timer
	if dash_timer == 0:
		dash_timer = dash_click_time
	else:
		# Se já estava contando, reinicia o timer
		dash_timer = dash_click_time

	# Verifica se atingiu o número necessário de cliques
	if side == "left" and click_count_left >= dash_clicks_required:
		_start_dash(-1)  # Inicia dash para esquerda
		click_count_left = 0  # Reseta contador
	elif side == "right" and click_count_right >= dash_clicks_required:
		_start_dash(1)  # Inicia dash para direita
		click_count_right = 0  # Reseta contador

# Processamento a cada frame (diferente de _physics_process que é para física)
func _process(delta: float) -> void:
	# Atualiza timer do dash
	if dash_timer > 0:
		dash_timer -= delta
	else:
		# Se timer acabou, reseta contadores
		click_count_left = 0
		click_count_right = 0

# ===============================
# 🔹 INICIAR DASH
# ===============================

# Inicia a sequência de dash
func _start_dash(direction: int):
	is_dashing = true  # Ativa flag de dash
	dash_direction = direction  # Define direção
	dash_time_left = dash_duration  # Configura duração
	print("⚡ Dash ativado para direção:", direction)

# ===============================
# 🔹 ATAQUE
# ===============================

# Função de ataque do jogador
func attack():
	is_attacking = true  # Ativa flag de ataque
	print("👊 Ataque iniciado!")
	# Aguarda a duração do ataque
	await get_tree().create_timer(attack_duration).timeout
	is_attacking = false  # Desativa flag de ataque
