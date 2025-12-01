extends CharacterBody2D

# ===============================
# 🔹 CONFIGURAÇÃO DE MOVIMENTO
# ===============================
@export var speed: float = 80.0
@export var change_direction_time: float = 3.0
@export var bounce_jitter: float = 30.0

# ===============================
# 🔹 SISTEMA DE ATAQUE
# ===============================
@export var bullet_scene: PackedScene
@export var bullet_speed: float = 200.0
@export var min_attack_interval: float = 0.5  # Tempo mínimo entre ataques
@export var max_attack_interval: float = 3.0  # Tempo máximo entre ataques

# ===============================
# 🔹 SISTEMA DE VIDA
# ===============================
@export var max_health: int = 200
var current_health: int = max_health
var is_dead: bool = false
var is_hurt: bool = false

# ===============================
# 🔹 VARIÁVEIS DE CONTROLE
# ===============================
var current_direction: Vector2 = Vector2.RIGHT
var change_timer: float = 0.0
var can_attack: bool = true
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var enemy_count = 0

# 🔥 SISTEMA SIMPLIFICADO DE ATAQUE
var attack_cooldown_timer: float = 0.0
var is_attacking: bool = false

# 🔥 NÓS DA CENA (verifique nomes no inspetor)
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var bullet_hell_timer: Timer = $BulletHellTimer
@onready var hurt_timer: Timer = $HurtSpriteTimer
@onready var hitbox: Area2D = $Hitbox
@onready var attack_spawn_points: Node2D = $AttackSpawnPoints

# ===============================
# 🔹 INICIALIZAÇÃO
# ===============================
func _ready():
	rng.randomize()
	_choose_random_direction()
	if sprite:
		sprite.play("idle")
	
	# 🔥 CARREGAR CENA DA BOLA AUTOMATICAMENTE
	if bullet_scene == null:
		bullet_scene = preload("res://CENAS/bola.tscn")
		print("✅ Bola carregada automaticamente: res://CENAS/bola.tscn")
	
	# conectar sinais de forma segura
	if hurt_timer:
		hurt_timer.connect("timeout", Callable(self, "_on_hurt_sprite_timer_timeout"))
	if hitbox:
		hitbox.connect("area_entered", Callable(self, "_on_hitbox_area_entered"))
	
	# 🔥 CONFIGURAR TIMER DE ATAQUE AUTOMÁTICO
	if bullet_hell_timer:
		bullet_hell_timer.wait_time = rng.randf_range(min_attack_interval, max_attack_interval)
		bullet_hell_timer.connect("timeout", Callable(self, "_on_bullet_hell_timer_timeout"))
		bullet_hell_timer.start()
		print("⏰ Primeiro ataque em: ", bullet_hell_timer.wait_time, " segundos")
	
	setup_collision_layers()
	
	if bullet_scene == null:
		push_warning("❌ bullet_scene não foi configurado!")
	else:
		print("✅ Bullet Scene configurado:", bullet_scene.resource_path)
	
	current_health = max_health
	print("🌑 Shinigami inicializado")

# ===============================
# 🔹 CONFIGURAÇÃO DE LAYERS
# ===============================
func setup_collision_layers():
	if is_instance_valid(self):
		set_collision_layer_value(3, true)  # enemies
		set_collision_mask_value(2, true)   # world
	if hitbox and is_instance_valid(hitbox):
		hitbox.set_collision_layer_value(6, true)      # enemy_attack  
		hitbox.set_collision_mask_value(5, true)       # player_attack

# ===============================
# 🔹 FÍSICA PRINCIPAL
# ===============================
func _physics_process(delta):
	if is_dead:
		return

	# Atualizar timer de direção
	change_timer -= delta
	if change_timer <= 0:
		_choose_random_direction()

	# Aplicar movimento (se não estiver hurt ou atacando)
	if not is_hurt and not is_attacking:
		velocity = current_direction * speed
		move_and_slide()
		_handle_collisions()

	# Atualizar sprite
	_update_sprite()

# ===============================
# 🔹 ATAQUE DAS BOLAS
# ===============================
func _start_attack():
	if is_dead or is_attacking or bullet_scene == null:
		return

	is_attacking = true
	print("🌑 Shinigami atacando!")
	
	# Animação de ataque
	if sprite:
		sprite.play("attack")

	# Pequeno delay antes de lançar as bolas
	await get_tree().create_timer(0.3).timeout
	
	if is_dead:
		is_attacking = false
		return

	# Lançar as bolas
	_launch_balls_from_markers()

	# Voltar para idle após o ataque
	await get_tree().create_timer(0.5).timeout
	
	if sprite and not is_dead:
		sprite.play("idle")
	
	is_attacking = false
	print("✅ Ataque finalizado, aguardando próximo...")

# ===============================
# 🔹 LANÇAR BOLAS DOS MARKER2D
# ===============================
func _launch_balls_from_markers():
	if bullet_scene == null:
		push_warning("bullet_scene não configurado!")
		return
	if not attack_spawn_points:
		push_warning("attack_spawn_points não encontrado!")
		return

	var markers = attack_spawn_points.get_children()
	var balls_launched = 0
	
	for marker in markers:
		if marker is Marker2D:
			var bullet = bullet_scene.instantiate()
			
			if bullet == null:
				push_warning("❌ Falha ao instanciar bala!")
				continue
				
			# Adicionar na cena correta
			var root = get_tree().current_scene
			if root:
				root.add_child(bullet)
			else:
				get_parent().add_child(bullet)

			bullet.global_position = marker.global_position

			# Configurar a bala
			if bullet.has_method("setup"):
				bullet.setup(bullet.global_position, bullet_speed)
				balls_launched += 1
			else:
				if "velocity" in bullet:
					bullet.velocity = Vector2.DOWN * bullet_speed
					balls_launched += 1
				elif "speed" in bullet and "direction" in bullet:
					bullet.speed = bullet_speed
					bullet.direction = Vector2.DOWN
					balls_launched += 1
				else:
					push_warning("⚠️ Bala não tem método setup() nem propriedades de movimento")
	
	print("🌑 Shinigami lançou ", balls_launched, " bolas!")

# ===============================
# 🔹 MOVIMENTO E COLISÃO
# ===============================
func _choose_random_direction():
	var random_angle = rng.randf_range(0.0, TAU)
	current_direction = Vector2(cos(random_angle), sin(random_angle)).normalized()
	change_timer = change_direction_time * rng.randf_range(0.8, 1.2)

func _handle_collisions():
	var count = get_slide_collision_count()

	for i in range(count):
		var collision = get_slide_collision(i)
		if collision:
			var normal = collision.get_normal()
			current_direction = current_direction.bounce(normal)

			var random_angle = rng.randf_range(-bounce_jitter, bounce_jitter)
			current_direction = current_direction.rotated(deg_to_rad(random_angle))

			change_timer = change_direction_time
			break

func _update_sprite():
	if not sprite:
		return
	if current_direction.x != 0:
		sprite.flip_h = current_direction.x < 0

# ===============================
# 🔹 SISTEMA DE DANO
# ===============================
func _on_hitbox_area_entered(area: Area2D):
	if area.is_in_group("player_attack") and not is_dead and not is_hurt:
		var damage = 10
		if area.has_method("get_damage"):
			damage = area.get_damage()
		take_damage(damage)

func take_damage(amount: int):
	if is_dead or is_hurt:
		return

	current_health -= amount
	current_health = max(0, current_health)
	print("🌑 Shinigami tomou ", amount, " de dano! Vida: ", current_health)

	if current_health > 0:
		is_hurt = true
		if sprite:
			sprite.play("hurt")
		if hurt_timer:
			hurt_timer.start()
	else:
		die()

func die():
	is_dead = true
	print("💀 Shinigami morreu! Indo para créditos...")
	
	# 🔥 PARAR O TIMER DE ATAQUE
	if bullet_hell_timer:
		bullet_hell_timer.stop()
	
	if sprite:
		sprite.play("hurt")
	
	# desativa colisões
	set_collision_layer_value(3, false)
	set_collision_mask_value(2, false)
	if hitbox:
		hitbox.monitoring = false
	
	# TROCAR PARA CENA DE CRÉDITOS
	await get_tree().create_timer(2.0).timeout
	change_to_credits_scene()

# ===============================
# 🔹 FUNÇÃO PARA TROCAR PARA CRÉDITOS
# ===============================
func change_to_credits_scene():
	print("🎬 Iniciando transição para créditos...")
	var credits_scene_path = "res://CENAS/creditos.tscn"
	
	if ResourceLoader.exists(credits_scene_path):
		var credits_scene = load(credits_scene_path)
		get_tree().change_scene_to_packed(credits_scene)
		print("✅ Transição para créditos realizada!")
	else:
		push_warning("❌ Cena de créditos não encontrada: " + credits_scene_path)
		print("🎉 PARABÉNS! VOCÊ DERROTOU O SHINIGAMI!")

# ===============================
# 🔹 SINAIS DOS TIMERS
# ===============================
func _on_bullet_hell_timer_timeout():
	# 🔥 EXECUTAR ATAQUE E CONFIGURAR PRÓXIMO TIMER
	if not is_dead and not is_hurt and not is_attacking:
		_start_attack()
		
		# 🔥 CONFIGURAR PRÓXIMO ATAQUE APÓS O CURRENTE TERMINAR
		await get_tree().create_timer(0.8).timeout  # Aguarda o ataque atual terminar
		
		if not is_dead and bullet_hell_timer:
			# Define novo tempo aleatório para próximo ataque
			bullet_hell_timer.wait_time = rng.randf_range(min_attack_interval, max_attack_interval)
			bullet_hell_timer.start()
			print("⏰ Próximo ataque em: ", bullet_hell_timer.wait_time, " segundos")

func _on_hurt_sprite_timer_timeout():
	is_hurt = false
	if sprite and not is_dead:
		sprite.play("idle")
