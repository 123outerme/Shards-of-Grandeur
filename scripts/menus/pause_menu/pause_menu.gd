extends Node2D
class_name PauseMenu
signal resume_game

@export var isPaused: bool = false

@onready var settingsMenu: SettingsMenu = get_node('Control/SettingsMenu')
@onready var resumeButton: Button = get_node("Control/Panel/VBoxContainer/ResumeButton")
@onready var settingsButton: Button = get_node('Control/Panel/VBoxContainer/SettingsButton')

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
	if settingsMenu.visible:
		settingsMenu.cancel_changes()
	SceneLoader.unpause_autonomous_movers()
	if PlayerFinder.player != null:
		PlayerFinder.player.textBox.refocus_choice(PlayerFinder.player.pickedChoice)
	resume_game.emit()

func _on_settings_button_pressed():
	settingsMenu.toggle_settings_menu(true)

func _on_save_quit_button_pressed():
	SaveHandler.save_data()
	SceneLoader.load_main_menu()

func _on_settings_menu_back_pressed():
	settingsButton.grab_focus()
