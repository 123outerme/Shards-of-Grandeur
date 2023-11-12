extends Node2D
class_name PauseMenu

@export var isPaused: bool = false

@onready var resumeButton: Button = get_node("Control/Panel/VBoxContainer/ResumeButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func toggle_pause():
	isPaused = not isPaused
	if isPaused:
		pause_game()
		resumeButton.grab_focus()
	else:
		_on_resume_button_pressed()

func pause_game():
	isPaused = true
	visible = true
	SceneLoader.pause_autonomous_movers()

func _on_resume_button_pressed():
	isPaused = false
	visible = false
	SceneLoader.unpause_autonomous_movers()

func _on_save_quit_button_pressed():
	SaveHandler.save_data()
	SceneLoader.load_main_menu()
