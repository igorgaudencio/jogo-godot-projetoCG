extends Control

@onready var start: Button = $MarginContainer/Menu_Buttons/Button


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://CENAS/Cena02.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		get_tree().change_scene_to_file("res://CENAS/Cena02.tscn")
