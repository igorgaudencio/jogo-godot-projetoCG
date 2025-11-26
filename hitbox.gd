extends Area2D

@export var damage: int = 10  # Dano que a hitbox do golem causa

func _ready():
	# Conecta o sinal quando o corpo entrar na área
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		# Aplica apenas o dano, sem knockback ou stun
		body.take_damage(damage)
