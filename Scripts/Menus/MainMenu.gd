extends Control

@onready var newGameButton: Button = get_node("Panel/VBoxContainer/NewGameButton")
@onready var resumeGameButton: Button = get_node("Panel/VBoxContainer/ResumeGameButton")

var characterName: String = 'Player'

@onready var newGameConfirmPanel: Panel = get_node("Panel/NewGameConfirmPanel")
@onready var noNewButton: Button = get_node("Panel/NewGameConfirmPanel/HBoxContainer/NoButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	newGameConfirmPanel.visible = false
	resumeGameButton.visible = SaveHandler.save_file_exists()
	if resumeGameButton.visible:
		resumeGameButton.grab_focus()
	else:
		newGameButton.grab_focus()

func new_game_name():
	# TODO: create character naming form
	start_new_game()

func start_new_game():
	SaveHandler.new_game(characterName)
	SceneLoader.load_game()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_settings_button_pressed():
	pass # TODO create settings menu

func _on_resume_game_button_pressed():
	SaveHandler.load_data()
	SceneLoader.load_game()

func _on_new_game_button_pressed():
	if resumeGameButton.visible:
		newGameConfirmPanel.visible = true
		noNewButton.grab_focus()
	else:
		new_game_name()

func _on_no_button_pressed():
	newGameConfirmPanel.visible = false
	if resumeGameButton.visible:
		resumeGameButton.grab_focus()
	else:
		newGameButton.grab_focus()

func _on_yes_button_pressed():
	new_game_name()
