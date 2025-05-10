extends Node2D
class_name PauseMenu
signal resume_game

@export var isPaused: bool = false

@onready var codexMenu: CodexMenu = get_node('Control/CodexMenu')
@onready var settingsMenu: SettingsMenu = get_node('Control/SettingsMenu')
@onready var saveGamePanel: SavesPanel = get_node('Control/SaveGamePanel')

@onready var pauseMenuPage: Control = get_node('Control/Panel/PauseMenuPage')
@onready var resumeButton: Button = get_node("Control/Panel/PauseMenuPage/VBoxContainer/ResumeButton")
@onready var codexButton: Button = get_node('Control/Panel/PauseMenuPage/VBoxContainer/CodexButton')
@onready var settingsButton: Button = get_node('Control/Panel/PauseMenuPage/VBoxContainer/SettingsButton')
@onready var saveButton: Button = get_node('Control/Panel/PauseMenuPage/VBoxContainer/SaveButton')

@onready var alertControl: Control = get_node('Control/AlertControl')
@onready var shade: ColorRect = get_node('Control/Shade')

const alertPanelPrefab = preload('res://prefabs/ui/alert_panel.tscn')

var settingsOnly: bool = false
var quitPressed: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed('game_decline') and not quitPressed:
		get_viewport().set_input_as_handled()
		toggle_pause()

func toggle_pause():
	if isPaused and quitPressed:
		return
	isPaused = not isPaused
	if isPaused:
		pause_game()
	else:
		pauseMenuPage.visible = true
		if codexMenu.visible:
			codexMenu.toggle_codex_menu(false)
		if saveGamePanel.visible:
			saveGamePanel.toggle_saves_panel(false)
		if settingsMenu.visible:
			settingsMenu.toggle_settings_menu(false)
		_on_resume_button_pressed()

func pause_game():
	isPaused = true
	visible = true
	initial_focus()
	SceneLoader.pause_autonomous_movers()
	if settingsOnly:
		_on_settings_button_pressed()

func initial_focus() -> void:
	resumeButton.grab_focus()

func _on_resume_button_pressed():
	isPaused = false
	visible = false
	codexMenu.visible = false
	if settingsMenu.visible:
		settingsMenu.cancel_changes()
	SceneLoader.unpause_autonomous_movers()
	if PlayerFinder.player != null and PlayerFinder.player.textBox.visible:
		PlayerFinder.player.textBox.refocus_choice(PlayerFinder.player.pickedChoice)
	resume_game.emit()

func _on_codex_button_pressed():
	pauseMenuPage.visible = false
	codexMenu.toggle_codex_menu(true)

func _on_settings_button_pressed():
	pauseMenuPage.visible = false
	settingsMenu.toggle_settings_menu(true)

func _on_save_button_pressed():
	pauseMenuPage.visible = false
	saveGamePanel.load_saves_panel()
	saveGamePanel.visible = true

func _on_quit_button_pressed():
	quitPressed = true
	get_viewport().gui_release_focus() # release focus so player can't spam quit button
	await fade_out_panel()
	SaveHandler.save_data()
	PlayerResources.saveFolder = ''
	PlayerResources.battleSaveFolder = ''
	SceneLoader.load_main_menu()

func _on_settings_menu_back_pressed():
	pauseMenuPage.visible = true
	if settingsOnly:
		_on_resume_button_pressed()
	else:
		settingsButton.grab_focus()

func _on_codex_menu_back_pressed():
	pauseMenuPage.visible = true
	codexButton.grab_focus()

func _on_save_game_panel_back_pressed():
	pauseMenuPage.visible = true
	saveButton.grab_focus()

func show_alert(message: String, lifetime: float = 2):
	var panel: AlertPanel = alertPanelPrefab.instantiate()
	panel.message = message
	panel.lifetime = lifetime
	alertControl.add_child(panel)

func fade_out_panel() -> void:
	SceneLoader.audioHandler.fade_out_music(0.5)
	if shade == null:
		return
	shade.visible = true
	shade.modulate = Color(0, 0, 0, 0)
	var shadeTween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	shadeTween.tween_property(shade, 'modulate', Color(0, 0, 0, 1.0), 0.5)
	await shadeTween.finished

func _on_save_game_panel_game_save_failed():
	show_alert('Warning: Save error occurred.')

func _on_save_game_panel_game_saved():
	show_alert('Save Successful!')
