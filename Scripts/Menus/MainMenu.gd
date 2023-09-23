extends Control

@onready var resumeGameButton: Button = get_node("Panel/VBoxContainer/ResumeGameButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	resumeGameButton.visible = SaveHandler.save_file_exists()
	pass # Replace with function body

func _on_quit_button_pressed():
	get_tree().quit()
	pass # Replace with function body.

func _on_settings_button_pressed():
	pass # Replace with function body.

func _on_resume_game_button_pressed():
	SaveHandler.load_data()
	SceneLoader.load_overworld()

func _on_new_game_button_pressed():
	SaveHandler.new_game()
	SceneLoader.load_overworld()
