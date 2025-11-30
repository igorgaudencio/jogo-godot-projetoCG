extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		# 🔥 IMPORTANTE: Chama a função do Player
		body.set_pode_entrar(true)
