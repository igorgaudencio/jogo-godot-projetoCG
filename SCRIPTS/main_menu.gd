extends Control

func _ready():
	# Conectar diretamente sem @onready (mais seguro para debugging)
	$Panel/Jogar.pressed.connect(_on_play_pressed)
	$Panel/Opções.pressed.connect(_on_options_pressed)
	$Panel/Sair.pressed.connect(_on_quit_pressed)
	
	print("Menu inicializado!")

func _on_play_pressed():
	print("Tentando carregar Cena01...")
	var resultado = get_tree().change_scene_to_file("res://CENAS/Cena01.tscn")
	if resultado == OK:
		print("Cena carregada com sucesso!")
	else:
		print("Erro ao carregar cena. Código: ", resultado)

func _on_options_pressed():
	print("Opções pressionado!")

func _on_quit_pressed():
	print("Saindo do jogo...")
	get_tree().quit()
