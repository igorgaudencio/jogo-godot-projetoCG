extends CharacterBody2D

const SPEED = 50.0
const GRAVITY = 980.0

@onready var wall_detector := $wall_detector as RayCast2D
@onready var texture := $texture as Sprite2D

var direction := 1
var can_detect := true  # ⬅️ CONTROLE DE PERMISSÃO
var detection_cooldown := 0.5  # ⬅️ TEMPO DE ESPERA

func _physics_process(delta: float) -> void:
	# Gravidade
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Inverte o raycast
	wall_detector.scale.x = direction
	
	# 🔍 DETECÇÃO COM COOLDOWN
	if can_detect and wall_detector.is_colliding():
		print("COLIDIU! Virando...")
		direction *= -1
		can_detect = false  # ⬅️ BLOQUEIA DETECÇÃO
		start_cooldown()    # ⬅️ INICIA COOLDOWN
	
	# Sprite
	texture.flip_h = (direction == -1)
	
	# Movimento
	velocity.x = direction * SPEED
	move_and_slide()

# ⏰ FUNÇÃO DO COOLDOWN
func start_cooldown():
	await get_tree().create_timer(detection_cooldown).timeout
	can_detect = true  # ⬅️ LIBERA DETECÇÃO NOVAMENTE
