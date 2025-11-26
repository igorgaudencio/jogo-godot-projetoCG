extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar

func _ready() -> void:
	# Configura a barra de vida
	health_bar.max_value = 100
	health_bar.value = 100
	
	# Tenta conectar com o player
	await get_tree().process_frame  # Espera um frame para garantir que todos os nós estão carregados
	try_connect_to_player()

func try_connect_to_player():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.has_signal("health_changed"):
			player.health_changed.connect(set_health)
			print("✅ HUD conectado ao player - Vida inicial: ", player.current_health)
			# Atualiza com o valor atual do player
			set_health(player.current_health)
			
			# Conecta também para o caso do player morrer e recarregar
			player.tree_exiting.connect(_on_player_exiting)
		else:
			print("❌ Player não tem sinal health_changed")
	else:
		print("⚠️ Player não encontrado no grupo 'player'")
		# Tenta novamente após um tempo
		await get_tree().create_timer(0.5).timeout
		try_connect_to_player()

func set_health(value: int) -> void:
	health_bar.value = value
	print("🩹 HUD atualizado - Vida: ", value)
	
	# Efeito visual quando a vida está baixa
	if value <= 30:
		health_bar.modulate = Color.RED
	elif value <= 50:
		health_bar.modulate = Color.YELLOW
	else:
		health_bar.modulate = Color.WHITE

func _on_player_exiting():
	# Quando o player é removido (morte), tenta reconectar quando voltar
	print("🔄 Player saiu da cena, aguardando reconexão...")
	await get_tree().create_timer(0.1).timeout
	try_connect_to_player()
