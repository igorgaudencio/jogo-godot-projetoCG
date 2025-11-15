extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar

func _ready() -> void:
	# Garante que a barra comece cheia
	set_health(100)
	set_health(50)
	# Tenta conectar com o player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("health_changed", Callable(self, "set_health"))
	else:
		print("⚠️ Nenhum player encontrado no grupo 'player'")

func set_health(value: int) -> void:
	health_bar.value = value
