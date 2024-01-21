extends Control

var playerName: String = 'Player'

@export var mainMenuMusic: AudioStream

@onready var newGameButton: Button = get_node("Panel/VBoxContainer/NewGameButton")
@onready var resumeGameButton: Button = get_node("Panel/VBoxContainer/ResumeGameButton")
@onready var settingsMenuButton: Button = get_node('Panel/VBoxContainer/SettingsButton')

@onready var newGameConfirmPanel: Panel = get_node("Panel/NewGameConfirmPanel")
@onready var noNewButton: Button = get_node("Panel/NewGameConfirmPanel/HBoxContainer/NoButton")

@onready var playerNamePanel: Panel = get_node("Panel/PlayerNamePanel")
@onready var nameInput: LineEdit = get_node("Panel/PlayerNamePanel/NameInput")
@onready var confirmButton: Button = get_node("Panel/PlayerNamePanel/HBoxContainer/ConfirmButton")

@onready var settingsMenu: SettingsMenu = get_node('SettingsMenu')

@onready var versionLabel: RichTextLabel = get_node('VersionLabel')

# Called when the node enters the scene tree for the first time.
func _ready():
	newGameConfirmPanel.visible = false
	playerNamePanel.visible = false
	resumeGameButton.visible = SaveHandler.save_file_exists()
	set_initial_main_menu_focus()
	versionLabel.text = ProjectSettings.get_setting('application/config/version', 'VERSION?')
	SceneLoader.audioHandler.play_music(mainMenuMusic, -1)

func set_initial_main_menu_focus():
	if resumeGameButton.visible:
		resumeGameButton.grab_focus()
	else:
		newGameButton.grab_focus()

func new_game_name():
	newGameConfirmPanel.visible = false
	playerNamePanel.visible = true
	nameInput.text = ''
	nameInput.grab_focus()

func start_new_game():
	SaveHandler.new_game(playerName)
	SceneLoader.load_game()

func _on_quit_button_pressed():
	SettingsHandler.save_data()
	get_tree().quit()

func _on_settings_button_pressed():
	settingsMenu.toggle_settings_menu(true)

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
	set_initial_main_menu_focus()

func _on_yes_button_pressed():
	new_game_name()

func _on_name_input_text_changed(new_text: String):
	confirmButton.disabled = len(new_text) == 0

func _on_name_input_text_submitted(new_text: String):
	if len(new_text) > 0:
		playerName = new_text
		start_new_game()

func _on_confirm_button_pressed():
	playerName = nameInput.text
	start_new_game()

func _on_cancel_button_pressed():
	playerNamePanel.visible = false
	set_initial_main_menu_focus()

func _on_settings_menu_back_pressed():
	settingsMenuButton.grab_focus()
