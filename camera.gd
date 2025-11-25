extends Camera2D

@export var target: Node2D  # Arraste o Player para aqui no Inspector
var follow_speed: float = 5.0

func _ready():
	# Se não definiu target, tenta encontrar automaticamente
	if not target:
		target = get_tree().get_first_node_in_group("player")
	
	# Configurações da câmera
	position_smoothing_enabled = true
	position_smoothing_speed = follow_speed
	make_current()  # Garante que esta é a câmera ativa

func _process(delta):
	if target and is_instance_valid(target):
		global_position = global_position.lerp(target.global_position, follow_speed * delta)
