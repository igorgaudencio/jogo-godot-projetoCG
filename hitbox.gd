extends Area2D

@export var damage: int = 20  # Dano que o golem causa

func _ready():
	# Conecta o sinal quando o corpo entrar na área
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		# Aplica apenas o dano, sem knockback ou stun
		body.take_damage(damage)
		
		# Efeitos visuais/sonoros específicos do golem (opcional)
		play_golem_attack_effects()

func play_golem_attack_effects():
	# Efeitos específicos do ataque do golem
	if get_parent().has_method("play_attack_sound"):
		get_parent().play_attack_sound()
	
	# Partículas de terra/pedra (opcional)
	spawn_rock_particles()

func spawn_rock_particles():
	# Aqui você pode adicionar partículas de pedra quebrando (opcional)
	pass
