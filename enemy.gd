extends CharacterBody2D

@export var speed: float = 80.0
@export var attack_range: float = 40.0
@export var attack_damage: int = 10
@export var max_health: int = 50
@export var attack_cooldown: float = 1.5

var current_health: int
var player: Node2D = null
var can_attack: bool = true

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer = $AttackCooldown
@onready var detection_area = $DetectionArea

func _ready():
	current_health = max_health
	detection_area.connect("body_entered", Callable(self, "_on_body_entered"))
	detection_area.connect("body_exited", Callable(self, "_on_body_exited"))
	attack_timer.timeout.connect(_on_attack_timeout)

func _physics_process(delta):
	if player == null:
		anim.play("idle")
		return

	var direction = (player.global_position - global_position).normalized()

	# Persegue o player
	if global_position.distance_to(player.global_position) > attack_range:
		velocity = direction * speed
		anim.play("walk")
	else:
		velocity = Vector2.ZERO
		attack()

	# Inverte o sprite conforme direção
	if direction.x != 0:
		anim.flip_h = direction.x < 0

	move_and_slide()

func attack():
	if can_attack and player:
		can_attack = false
		anim.play("attack")
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
		attack_timer.start(attack_cooldown)

func _on_attack_timeout():
	can_attack = true

func take_damage(amount: int):
	current_health -= amount
	print("💢 Inimigo levou dano:", amount, "| Vida:", current_health)
	if current_health <= 0:
		die()

func die():
	anim.play("die")
	await anim.animation_finished
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player = body

func _on_body_exited(body):
	if body == player:
		player = null
