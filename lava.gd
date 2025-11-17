extends Area2D

@export var damage: int = 50
@export var damage_interval: float = 1.0

var player_in_lava = null

@onready var timer = $DamageTimer

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_lava = body
		timer.start()
		print("🔥 Player entrou na lava!")

func _on_body_exited(body):
	if body == player_in_lava:
		player_in_lava = null
		timer.stop()
		print("❄ Player saiu da lava")

func _on_DamageTimer_timeout():
	if player_in_lava and player_in_lava.has_method("take_damage"):
		player_in_lava.take_damage(damage)
		print("💥 Dano causado:", damage)
