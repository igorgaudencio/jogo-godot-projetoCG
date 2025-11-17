extends Control

func _ready():
	$Panel/Jogar.pressed.connect(_on_play_pressed)
	$Panel/Opções.pressed.connect(_on_options_pressed)
	$Panel/Sair.pressed.connect(_on_quit_pressed)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://Cena01.tscn")

func _on_options_pressed():
	print("Opções ainda não implementadas!")

func _on_quit_pressed():
	get_tree().quit()
