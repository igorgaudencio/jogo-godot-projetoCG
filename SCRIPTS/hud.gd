extends CanvasLayer

@onready var health_bar: TextureProgressBar = $HealthBar

func _ready() -> void:
	# Configura a barra de vida
	health_bar.max_value = 100
	health_bar.value = 100
	
	# 🔥 CONFIGURAÇÃO VISUAL ADIADA
	setup_health_bar_visual()
	
	# Tenta conectar com o player
	await get_tree().process_frame
	try_connect_to_player()

func setup_health_bar_visual():
	# 🔥 USA set_deferred() PARA EVITAR CONFLITO DE ANCHORS
	call_deferred("_deferred_setup_health_bar")

func _deferred_setup_health_bar():
	health_bar.visible = true
	health_bar.size = Vector2(200, 24)
	health_bar.position = Vector2(20, 20)
	
	# 🔥 CONFIGURA ANCHORS
	health_bar.anchor_left = 0.0
	health_bar.anchor_right = 0.0
	health_bar.anchor_top = 0.0
	health_bar.anchor_bottom = 0.0
	
	if health_bar.texture_progress == null:
		print("🎨 Criando estilo visual para HealthBar...")
		
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color.GREEN
		fill_style.border_width_bottom = 1
		fill_style.border_width_top = 1
		fill_style.border_width_left = 1
		fill_style.border_width_right = 1
		fill_style.border_color = Color.WHITE
		fill_style.corner_radius_top_left = 5
		fill_style.corner_radius_top_right = 5
		fill_style.corner_radius_bottom_left = 5
		fill_style.corner_radius_bottom_right = 5
		
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color(0.2, 0.2, 0.2, 0.8)
		bg_style.border_width_bottom = 2
		bg_style.border_width_top = 2
		bg_style.border_width_left = 2
		bg_style.border_width_right = 2
		bg_style.border_color = Color.BLACK
		bg_style.corner_radius_top_left = 5
		bg_style.corner_radius_top_right = 5
		bg_style.corner_radius_bottom_left = 5
		bg_style.corner_radius_bottom_right = 5
		
		health_bar.add_theme_stylebox_override("fill", fill_style)
		health_bar.add_theme_stylebox_override("background", bg_style)
	
	add_health_label()

func add_health_label():
	var health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "100 / 100"
	health_label.position = Vector2(health_bar.position.x + 70, health_bar.position.y + 2)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	health_label.add_theme_color_override("font_color", Color.WHITE)
	health_label.add_theme_font_size_override("font_size", 14)
	health_label.add_theme_constant_override("outline_size", 2)
	health_label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	add_child(health_label)

func try_connect_to_player():
	print("🔍 Tentando conectar ao player...")
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("✅ Player encontrado: ", player.name)
		
		if player.has_signal("health_changed"):
			# 🔥 DESCONECTA ANTES PARA EVITAR DUPLICATAS
			if player.health_changed.is_connected(set_health):
				player.health_changed.disconnect(set_health)
			
			player.health_changed.connect(set_health)
			print("✅ HUD conectado ao player - Vida inicial: ", player.current_health)
			set_health(player.current_health)
			
			if not player.tree_exiting.is_connected(_on_player_exiting):
				player.tree_exiting.connect(_on_player_exiting)
				
		else:
			print("❌ Player não tem sinal health_changed")
			await get_tree().create_timer(1.0).timeout
			try_connect_to_player()
	else:
		print("⚠️ Player não encontrado no grupo 'player'")
		await get_tree().create_timer(0.5).timeout
		try_connect_to_player()

func set_health(value: int) -> void:
	health_bar.value = value
	
	var health_label = get_node_or_null("HealthLabel")
	if health_label:
		health_label.text = str(value) + " / 100"
	
	if value <= 30:
		health_bar.modulate = Color.RED
		var fill_style = health_bar.get_theme_stylebox("fill")
		if fill_style:
			fill_style.bg_color = Color.RED
	elif value <= 50:
		health_bar.modulate = Color.YELLOW
		var fill_style = health_bar.get_theme_stylebox("fill")
		if fill_style:
			fill_style.bg_color = Color.YELLOW
	else:
		health_bar.modulate = Color.WHITE
		var fill_style = health_bar.get_theme_stylebox("fill")
		if fill_style:
			fill_style.bg_color = Color.GREEN

func _on_player_exiting():
	print("🔄 Player saindo da cena...")
	
	# 🔥 VERIFICA SE A ÁRVORE AINDA EXISTE
	if is_inside_tree() and get_tree() != null:
		await get_tree().create_timer(0.5).timeout
		try_connect_to_player()
