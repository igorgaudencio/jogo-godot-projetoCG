extends CanvasLayer

@onready var resume: Button = $Menu_Holder/Resume

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		visible = true
		get_tree().paused = true
		resume.grab_focus()

func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	Globals.temp_score = 0
	Globals.score = 0
	self.get_tree().quit()
