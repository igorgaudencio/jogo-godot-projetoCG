extends CharacterBody2D

# ===============================
# 🔹 VARIÁVEIS DE VIDA
# ===============================
@export var max_health: int = 100
var current_health: int = max_health
var is_dead: bool = false

signal health_changed(value)
# ===============================
# 🔹 MOVIMENTO E FÍSICA
# ===============================
@export var speed: float = 150.0
@export var jump_force: float = -400.0
@export var gravity: float = 900.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

# ===============================
# 🔹 DASH CONFIGURAÇÃO
# ===============================
@export var dash_speed: float = 450.0
@export var dash_duration: float = 0.2
@export var dash_clicks_required: int = 4
@export var dash_click_time: float = 0.4 # segundos entre cliques
var dash_timer: float = 0.0
var dash_direction: int = 0
var click_count_left: int = 0
var click_count_right: int = 0
var dash_time_left: float = 0.0
var is_dashing: bool = false

# ===============================
# 🔹 ATAQUE
# ===============================
var is_attacking: bool = false
@export var attack_duration: float = 0.3

# ===============================
# 🔹 DANO E MORTE
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

	# Gravidade
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

	# Espelhar sprite
	if velocity.x != 0:
		anim.flip_h = velocity.x < 0

	move_and_slide()

# ===============================
# 🔹 DASH HANDLER
# ===============================
func _handle_dash_input(direction: int):
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

func _process(delta: float) -> void:
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
	print("⚡ Dash ativado para direção:", direction)

# ===============================
# 🔹 ATAQUE
# ===============================
func attack():
	is_attacking = true
	print("👊 Ataque iniciado!")
	await get_tree().create_timer(attack_duration).timeout
	is_attacking = false
