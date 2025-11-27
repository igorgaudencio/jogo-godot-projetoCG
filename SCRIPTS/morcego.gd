extends CharacterBody2D

const SPEED = 80.0
const CHASE_SPEED = 120.0

# Nós da cena
@onready var texture := $texture as Sprite2D
@onready var animation_player := $anim as AnimationPlayer
@onready var detection_area := $DetectionArea as Area2D

# Variáveis do inimigo
var player_ref: CharacterBody2D = null
var direction := 1
func _ready():
	# Conecta os sinais de detecção
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	print("🦇 Morcego inicializado - Modo simples: Detectar e Perseguir")

func _physics_process(delta: float) -> void:
	# Movimento vertical zero (voando)
	velocity.y = 0
	
	if player_ref and is_instance_valid(player_ref):
		# MODO PERSEGUIÇÃO: Player detectado
		chase_behavior()
	else:
		# MODO PATRULHA: Nenhum player detectado
		patrol_behavior()
	
	move_and_slide()

# Comportamento de patrulha simples
func patrol_behavior():
	# Movimento básico de patrulha
	velocity.x = direction * SPEED
	
	# Animação de voo
	if animation_player and animation_player.has_animation("fly"):
		animation_player.play("fly")
	
	# Inverte a direção ocasionalmente (opcional)
	# Pode adicionar raycast para paredes se quiser

# Comportamento de perseguição
func chase_behavior():
	if player_ref and is_instance_valid(player_ref):
		# Calcula direção até o player
		var player_direction = sign(player_ref.global_position.x - global_position.x)
		
		# Atualiza direção e sprite
		direction = player_direction
		texture.flip_h = (direction == 1)
		
		# Move em direção ao player
		velocity.x = direction * CHASE_SPEED
		
		# Animação de perseguição
		if animation_player and animation_player.has_animation("fly"):
			animation_player.play("fly")

# Sinais de detecção do player
func _on_detection_area_body_entered(body: Node2D):
	if body.is_in_group("player") and body is CharacterBody2D:
		print("🔍 Morcego detectou o player!")
		player_ref = body

func _on_detection_area_body_exited(body: Node2D):
	if body == player_ref:
		print("👋 Player saiu da área de detecção")
		player_ref = null
