extends CharacterBody2D

const SPEED = 50.0
const JUMP_VELOCITY = -400.0
const GRAVITY = 980.0  # ⬅️ ADICIONE GRAVIDADE CONSTANTE

@onready var wall_detector := $wall_detector as RayCast2D
@onready var texture := $texture as Sprite2D

var direction := 1

func _physics_process(delta: float) -> void:
	# 🔹 GRAVIDADE
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# 🔹 DETECÇÃO DE PAREDE
	if wall_detector.is_colliding():
		direction *= -1  # ⬅️ CORREÇÃO AQUI!
		wall_detector.position.x *= -1  # Opcional: ajusta a posição do raycast
		wall_detector.scale.x *= -1
	
	if direction == 1:
		texture.flip_h = false
	else:
		texture.flip_h = true
	
	# 🔹 MOVIMENTO HORIZONTAL (apenas no chão ou sempre?)
	velocity.x = direction * SPEED
	
	# 🔹 APLICA MOVIMENTO
	move_and_slide()
