extends Control

@export var mainMenuMusic: AudioStream
@export var mainMenuLoopMusic: AudioStream
@export var activateDebugModeSfx: AudioStream = null

## for some reason, this includes down-events and up-events even if checking event.pressed to be true...
## intention is 5 clicks to enter Debug mode
const DEBUG_CLICKS = 10

var playerName: String = 'Player'
var nameInputFocused: bool = false

@onready var mainMenuPage: Control = get_node("Panel/MainMenuPage")
@onready var newGameButton: Button = get_node("Panel/MainMenuPage/VBoxContainer/NewGameButton")
@onready var resumeGameButton: Button = get_node("Panel/MainMenuPage/VBoxContainer/ResumeGameButton")
@onready var settingsMenuButton: Button = get_node('Panel/MainMenuPage/VBoxContainer/SettingsButton')
@onready var creditsButton: Button = get_node('Panel/MainMenuPage/VBoxContainer/CreditsButton')

@onready var loadGamePanel: SavesPanel = get_node('Panel/LoadGamePanel')

@onready var newGameConfirmPanel: Panel = get_node("Panel/NewGameConfirmPanel")
@onready var overwriteWarningLabel: RichTextLabel = get_node('Panel/NewGameConfirmPanel/OverwriteWarningLabel')
@onready var noNewButton: Button = get_node("Panel/NewGameConfirmPanel/HBoxContainer/NoButton")

@onready var playerNamePanel: Panel = get_node("Panel/PlayerNamePanel")
@onready var nameInput: LineEdit = get_node("Panel/PlayerNamePanel/NameInput")
@onready var confirmButton: Button = get_node("Panel/PlayerNamePanel/HBoxContainer/ConfirmButton")
@onready var virtualKeyboard: VirtualKeyboard = get_node('Panel/PlayerNamePanel/VirtualKeyboard')

@onready var settingsMenu: SettingsMenu = get_node('SettingsMenu')

@onready var creditsPanel: CreditsPanel = get_node('Panel/CreditsPanel')

@onready var versionLabel: RichTextLabel = get_node('Panel/MainMenuPage/VersionLabel')

var debugCounter: int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	newGameConfirmPanel.visible = false
	playerNamePanel.visible = false
	loadGamePanel.load_saves_panel()
	resumeGameButton.visible = loadGamePanel.get_num_saves() != 0
	set_initial_main_menu_focus()
	versionLabel.text = 'v' + ProjectSettings.get_setting('application/config/version', 'VERSION?')
	SceneLoader.audioHandler.play_music(mainMenuMusic)
	SceneLoader.audioHandler.music_playback_complete.connect(_music_playback_complete)
	SettingsHandler.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()

func _unhandled_input(event):
	var declineIsShift: bool = false
	for ev: InputEvent in InputMap.action_get_events('game_decline'):
		if ev is InputEventKey:
			if ev.keycode == KEY_SHIFT:
				declineIsShift = true
	if visible and event.is_action_pressed("game_decline") and not (virtualKeyboard.visible or (nameInputFocused and declineIsShift)):
		get_viewport().set_input_as_handled()
		if newGameConfirmPanel.visible:
			_on_no_button_pressed.call_deferred()
		elif playerNamePanel.visible:
			_on_cancel_button_pressed.call_deferred()

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
	SceneLoader.audioHandler.fade_out_music()
	SaveHandler.new_game(playerName)
	SceneLoader.load_game()

func _on_quit_button_pressed():
	SettingsHandler.save_data()
	get_tree().quit()

func _on_settings_button_pressed():
	mainMenuPage.visible = false
	settingsMenu.toggle_settings_menu(true)

func _on_resume_game_button_pressed():
	mainMenuPage.visible = false
	loadGamePanel.load_saves_panel()
	loadGamePanel.visible = true

func _on_new_game_button_pressed():
	mainMenuPage.visible = false
	if resumeGameButton.visible:
		newGameConfirmPanel.visible = true
		overwriteWarningLabel.visible = loadGamePanel.has_quick_save()
		noNewButton.grab_focus()
	else:
		new_game_name()

func _on_no_button_pressed():
	newGameConfirmPanel.visible = false
	mainMenuPage.visible = true
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
	mainMenuPage.visible = true
	set_initial_main_menu_focus()

func _on_settings_menu_back_pressed():
	mainMenuPage.visible = true
	settingsMenuButton.grab_focus()

func _on_name_input_gui_input(event):
	# if ui cancel (Escape) has been pressed to unfocus the input
	if event.is_action_pressed('ui_cancel'):
		confirmButton.grab_focus()

func _on_virtual_keyboard_key_pressed(character):
	if playerNamePanel.visible:
		nameInput.text += character
		_on_name_input_text_changed(nameInput.text)

func _on_virtual_keyboard_backspace_pressed():
	if playerNamePanel.visible:
		nameInput.text = nameInput.text.substr(0, len(nameInput.text) - 1)
		_on_name_input_text_changed(nameInput.text)

func _on_virtual_keyboard_keyboard_hidden():
	confirmButton.grab_focus()

func _on_virtual_keyboard_enter_pressed():
	confirmButton.grab_focus()

func _on_settings_changed():
	virtualKeyboard.enabled = SettingsHandler.gameSettings.useVirtualKeyboard
	nameInput.virtual_keyboard_enabled = not SettingsHandler.gameSettings.useVirtualKeyboard
	if not virtualKeyboard.enabled:
		virtualKeyboard.hide_keyboard()

func _on_credits_button_pressed():
	mainMenuPage.visible = false
	creditsPanel.visible = true
	creditsPanel.backButton.grab_focus()

func _on_credits_back_button_pressed():
	creditsPanel.visible = false
	mainMenuPage.visible = true
	creditsButton.grab_focus()

func _on_name_input_focus_entered():
	nameInputFocused = true

func _on_name_input_focus_exited():
	nameInputFocused = false

func _on_load_game_panel_back_pressed():
	mainMenuPage.visible = true
	resumeGameButton.grab_focus()

func _on_debug_click_control_gui_input(event: InputEvent) -> void:
	var doIncrement: bool = false
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			doIncrement = true
	elif event is InputEventScreenTouch:
		if event.pressed:
			doIncrement = true
	
	if doIncrement:
		print('increment')
		debugCounter += 1
		if debugCounter == DEBUG_CLICKS:
			SceneLoader.debug = true
			SceneLoader.audioHandler.play_sfx(activateDebugModeSfx)

func _music_playback_complete():
	SceneLoader.audioHandler.play_music(mainMenuLoopMusic, -1)
	SceneLoader.audioHandler.music_playback_complete.disconnect(_music_playback_complete)
