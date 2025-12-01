extends Area2D

@export var speed: float = 200.0
@export var damage: int = 10
@export var respawn_time: float = 0  # tempo para reaparecer outra bola

var velocity: Vector2 = Vector2.DOWN * speed
var can_respawn: bool = true

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	if anim_sprite:
		anim_sprite.play("attack")
	
	setup_collision_layers()
	body_entered.connect(_on_body_entered)
	
	# Verifica se o timer existe antes de configurar

func setup(spawn_pos: Vector2, spd: float):
	global_position = spawn_pos
	speed = spd
	velocity = Vector2.DOWN * speed

func setup_collision_layers():
	set_collision_layer_value(6, true)  # enemy_attack
	set_collision_mask_value(1, true)   # player
	set_collision_mask_value(2, true)   # world

func _physics_process(delta):
	position += velocity * delta
	
	if global_position.y > get_viewport().get_visible_rect().size.y + 100:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		print("💥 Bola deu ", damage, " de dano no player!")
		body.take_damage(damage)
		queue_free()
	elif body.is_in_group("world"):
		queue_free()

func _on_RespawnTimer_timeout():
	if can_respawn:
		var root = get_tree().current_scene
		if root:
			var new_ball = duplicate()
			new_ball.global_position = Vector2(randi() % 400 + 50, -50)
			root.add_child(new_ball)
