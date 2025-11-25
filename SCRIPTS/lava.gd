extends Area2D

@export var damage: int = 500
@export var damage_interval: float = 1.0

var player_in_lava = null
@onready var timer = $DamageTimer

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_lava = body
		timer.start(damage_interval)
		print("🔥 Player entrou na lava!")
		
		# Dano imediato ao entrar
		if player_in_lava.has_method("take_damage"):
			player_in_lava.take_damage(damage)

func _on_body_exited(body):
	if body.is_in_group("player") and body == player_in_lava:
		player_in_lava = null
		timer.stop()
		print("❄ Player saiu da lava")

func _on_DamageTimer_timeout():
	if player_in_lava and is_instance_valid(player_in_lava):
		if player_in_lava.has_method("take_damage"):
			player_in_lava.take_damage(damage)
			print("💥 Dano periódico na lava: ", damage)
	else:
		timer.stop()
