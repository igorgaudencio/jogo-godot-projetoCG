extends Area2D

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.take_damage(150)  # dano fixo, pode variar
