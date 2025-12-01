extends Control

@onready var start: Button = $MarginContainer/Menu_Buttons/Start

func _ready() -> void:
	start.grab_focus()

func _on_start_pressed() -> void:

	get_tree().change_scene_to_file("res://CENAS/cutscene01.tscn")


func _on_load_pressed() -> void:
	#TODO ver como carregar arquivos anteriores
	pass


func _on_quit_pressed() -> void:

	get_tree().quit()
