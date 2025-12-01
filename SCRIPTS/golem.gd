extends CharacterBody2D

const SPEED: float = 50.0
const CHASE_SPEED: float = 80.0
const GRAVITY: float = 980.0

# Nós (ajuste nomes se necessário — já usei os que você passou)
@onready var wall_detector := $wall_detector as RayCast2D
@onready var texture := $texture as Sprite2D
@onready var detection_area := $DetectionArea as Area2D
@onready var attack_area := $attack1 as Area2D
@onready var animation_player := $anim as AnimationPlayer
@onready var hurtbox := $hitbox as Area2D

# Vida
@export var max_health: int = 100
var current_health: int = max_health
var is_dead: bool = false

# Ataque
@export var attack_damage: int = 20
var can_attack: bool = true
@export var attack_cooldown: float = 2.0
var is_attacking: bool = false

var direction := 1
var can_detect := true
var detection_cooldown := 0.5
var last_direction := 1

# Estados
enum State { PATROL, CHASE, ATTACK, HURT, DEAD }
var current_state = State.PATROL
var player_ref: CharacterBody2D = null

func _ready() -> void:
	add_to_group("enemy")

	# Conecta sinais
	if detection_area:
		detection_area.body_entered.connect(_on_detection_area_body_entered)
		detection_area.body_exited.connect(_on_detection_area_body_exited)
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
	if hurtbox:
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

	# Conecta sinal de animação finalizada
	if animation_player and animation_player.has_signal("animation_finished"):
		animation_player.animation_finished.connect(_on_animation_finished)

	update_attack_area_position()
	setup_collision_layers()

	current_health = max_health
	print("🪨 Golem inicializado - Vida:", current_health)

func setup_collision_layers() -> void:
	# Ajuste conforme seu projeto (índices podem variar)
	set_collision_layer_value(3, true)  # corpo inimigo
	set_collision_mask_value(2, true)

	if detection_area:
		detection_area.set_collision_layer_value(3, true)
		detection_area.set_collision_mask_value(1, true)

	if attack_area:
		attack_area.set_collision_layer_value(5, true)
		attack_area.set_collision_mask_value(6, true)

	if hurtbox:
		hurtbox.set_collision_layer_value(6, true)
		hurtbox.set_collision_mask_value(5, true)

func update_attack_area_position() -> void:
	if attack_area and is_instance_valid(attack_area):
		if texture.flip_h:
			attack_area.position = Vector2(-40, 0)
		else:
			attack_area.position = Vector2(40, 0)

func _physics_process(delta: float) -> void:
	if is_dead or current_state == State.DEAD or not is_instance_valid(self):
		return

	# Gravidade
	if not is_on_floor():
		velocity.y += GRAVITY * delta

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

func patrol_behavior(_delta: float) -> void:
	# mantem raycast alinhado
	wall_detector.scale.x = direction

	if can_detect and wall_detector.is_colliding():
		print("🔄 Golem virando...")
		direction *= -1
		can_detect = false
		start_cooldown()

	texture.flip_h = (direction == -1)

	if last_direction != direction:
		update_attack_area_position()
		last_direction = direction

	velocity.x = direction * SPEED

	if animation_player and is_instance_valid(animation_player):
		if animation_player.has_animation("walk"):
			animation_player.play("walk")

func chase_behavior(_delta: float) -> void:
	if player_ref and is_instance_valid(player_ref):
		var player_direction = sign(player_ref.global_position.x - global_position.x)
		if player_direction == 0:
			player_direction = direction
		direction = player_direction
		texture.flip_h = (direction == -1)

		if last_direction != direction:
			update_attack_area_position()
			last_direction = direction

		velocity.x = direction * CHASE_SPEED

		var distance_to_player = abs(player_ref.global_position.x - global_position.x)
		if distance_to_player < 80 and can_attack and not is_attacking:
			current_state = State.ATTACK
			print("🎯 Golem iniciando ataque!")

		# animação de corrida se existir
		if animation_player and is_instance_valid(animation_player):
			if animation_player.has_animation("run"):
				animation_player.play("run")
			elif animation_player.has_animation("walk"):
				animation_player.play("walk")
	else:
		current_state = State.PATROL
		player_ref = null
		print("👋 Golem perdeu o player, voltando à patrulha")

# Nota: usamos timers/awaits para janela de dano, mas NÃO reiniciamos a animação
func attack_behavior(_delta: float) -> void:
	velocity.x = 0

	if not can_attack or is_attacking or is_dead:
		return

	# Marca o ataque em andamento
	is_attacking = true
	print("💥 Golem atacando!")

	# Toca a animação UMA vez (nome fornecido por você: "hit")
	if animation_player and is_instance_valid(animation_player) and animation_player.has_animation("hit"):
		animation_player.play("hit")
	else:
		# se não tiver animação, ainda assim executa a hitbox com tempos padrão
		print("⚠️ Animação 'hit' não encontrada, usando timers fallback")

	# Delay até janela de dano (ajuste 0.3 se precisar)
	await get_tree().create_timer(0.3).timeout
	if is_dead or not is_instance_valid(self):
		return

	# Ativa hitbox
	if attack_area and is_instance_valid(attack_area):
		attack_area.monitoring = true
		print("✅ AttackArea ativada")

	# Duração da janela de dano (0.2s por padrão)
	await get_tree().create_timer(0.2).timeout
	if is_dead or not is_instance_valid(self):
		return

	# Desativa hitbox
	if attack_area and is_instance_valid(attack_area):
		attack_area.monitoring = false
		print("❌ AttackArea desativada")

	# Inicia cooldown do ataque sem liberar is_attacking (isso será liberado pelo animation_finished)
	can_attack = false
	# Rodamos o cooldown mas não alteramos is_attacking aqui
	await get_tree().create_timer(attack_cooldown).timeout
	if is_dead or not is_instance_valid(self):
		return
	can_attack = true
	print("⏱️ Cooldown do ataque finalizado")

	# Se a animação terminou antes do cooldown, o _on_animation_finished já terá trocado o estado.
	# Caso a animação NÃO esteja sendo reproduzida (ex.: sem animação), forçamos retorno de estado:
	if not is_attacking:
		if player_ref and is_instance_valid(player_ref):
			current_state = State.CHASE
		else:
			current_state = State.PATROL

func hurt_behavior(_delta: float) -> void:
	velocity.x = 0
	# animação de hurt é controlada em take_damage()

func _on_animation_finished(anim_name: String) -> void:
	# Você informou que a animação de ataque é "hit"
	if anim_name == "hit":
		print("✅ Animação 'hit' terminou")
		is_attacking = false
		# volta ao estado apropriado
		if player_ref and is_instance_valid(player_ref):
			current_state = State.CHASE
		else:
			current_state = State.PATROL
	elif anim_name == "hurt":
		print("✅ Animação 'hurt' terminou")
		if player_ref and is_instance_valid(player_ref):
			current_state = State.CHASE
		else:
			current_state = State.PATROL
	elif anim_name == "dead" or anim_name == "death":
		# Quando morrer, caso você toque animação de morte, após terminar free
		if is_instance_valid(self):
			queue_free()

func start_cooldown() -> void:
	await get_tree().create_timer(detection_cooldown).timeout
	if not is_dead and is_instance_valid(self):
		can_detect = true

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body is CharacterBody2D and not is_dead:
		print("🔍 Golem detectou o player!")
		player_ref = body
		current_state = State.CHASE

func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == player_ref and not is_dead:
		print("👋 Player saiu da área de detecção")
		player_ref = null
		current_state = State.PATROL

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage") and not is_dead:
		print("💢 Golem causou %s de dano ao player!" % attack_damage)
		body.take_damage(attack_damage)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_attack") and area.has_method("get_damage") and not is_dead:
		var damage = area.get_damage()
		take_damage(damage)

func take_damage(amount: int) -> void:
	if is_dead or current_state == State.DEAD or not is_instance_valid(self):
		return

	current_health -= amount
	current_health = max(0, current_health)
	print("🪨 Golem tomou %s de dano! Vida: %s" % [amount, current_health])

	if current_health > 0:
		current_state = State.HURT
		if animation_player and animation_player.has_animation("hurt"):
			animation_player.play("hurt")
		else:
			print("💢 Golem ferido!")

		# pequena pausa para o hurt (não bloqueia signals)
		await get_tree().create_timer(0.5).timeout
		if is_dead or not is_instance_valid(self):
			return
		if player_ref and is_instance_valid(player_ref):
			current_state = State.CHASE
		else:
			current_state = State.PATROL
	else:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	current_state = State.DEAD
	print("💀 Golem morreu!")

	# Cancela ataques
	is_attacking = false
	can_attack = false

	# Toca animação de morte se existir
	if animation_player and is_instance_valid(animation_player):
		if animation_player.has_animation("dead"):
			animation_player.play("dead")
		elif animation_player.has_animation("death"):
			animation_player.play("death")

	# Desativa colisões e áreas
	set_collision_layer_value(3, false)
	set_collision_mask_value(2, false)

	if detection_area and is_instance_valid(detection_area):
		detection_area.monitoring = false
	if attack_area and is_instance_valid(attack_area):
		attack_area.monitoring = false
	if hurtbox and is_instance_valid(hurtbox):
		hurtbox.monitoring = false

	# Espera sinal de término de animação de morte (se houver); fallback timer
	if animation_player and is_instance_valid(animation_player) and (animation_player.has_animation("dead") or animation_player.has_animation("death")):
		# aguardamos a próxima emissão do sinal animation_finished (quando a animação finalizar)
		await animation_player.animation_finished
		if is_instance_valid(self):
			queue_free()
	else:
		await get_tree().create_timer(1.0).timeout
		if is_instance_valid(self):
			queue_free()
