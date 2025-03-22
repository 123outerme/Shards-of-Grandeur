extends Control
class_name SettingsMenu

signal back_pressed

@onready var vboxContainer: VBoxContainer = get_node('Panel/VBoxContainer')

@onready var backButton: Button = get_node('Panel/VBoxContainer/BackButton')
@onready var generalButton: Button = get_node('Panel/VBoxContainer/GeneralButton')
@onready var controlsButton: Button = get_node('Panel/VBoxContainer/ControlsButton')
@onready var audioButton: Button = get_node('Panel/VBoxContainer/AudioButton')
@onready var gameLogsButton: Button = get_node('Panel/VBoxContainer/GameLogsButton')

@onready var generalSection: GeneralSection = get_node('Panel/SubsectionPanel/GeneralSection')
@onready var controlsSection: ControlsSection = get_node('Panel/SubsectionPanel/ControlsSection')
@onready var audioSection: AudioSection = get_node('Panel/SubsectionPanel/AudioSection')

@onready var gameLogsPanel: GameLogsPanel = get_node('LogsPanel')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _unhandled_input(event):
	if visible and event.is_action_pressed("game_decline"):
		get_viewport().set_input_as_handled()
		if not (controlsSection.visible and controlsSection.trapFocus):
			_on_back_button_pressed()

func toggle_settings_menu(showing: bool):
	visible = showing
	if visible:
		initial_focus()
		generalButton.button_pressed = true
		generalSection.toggle_section(true)
		set_button_right_neighbors(generalSection.onscreenKeyboardButton)
		controlsSection.toggle_section(false)
		audioSection.toggle_section(false)
		audioSection.connect_top_setting_to(audioButton)
	else:
		_on_back_button_pressed()

func initial_focus():
	backButton.grab_focus()

func cancel_changes():
	controlsSection._on_cancel_button_pressed()
	visible = false

func set_button_right_neighbors(control: Control):
	for node in vboxContainer.get_children():
		var button: Button = node as Button
		if control != null:
			button.focus_neighbor_right = button.get_path_to(control)
			control.focus_neighbor_left = control.get_path_to(button)
		else:
			button.focus_neighbor_right = ''

func _on_back_button_pressed():
	visible = false
	controlsSection._on_cancel_button_pressed()
	_on_general_button_toggled(true)
	SettingsHandler.save_data()
	back_pressed.emit()

func _on_general_button_toggled(toggled_on):
	if toggled_on:
		controlsSection.toggle_section(false)
		controlsButton.button_pressed = false
		audioSection.toggle_section(false)
		audioButton.button_pressed = false
		set_button_right_neighbors(generalSection.onscreenKeyboardButton)
	generalSection.toggle_section(toggled_on)

func _on_controls_button_toggled(toggled_on):
	if toggled_on:
		generalSection.toggle_section(false)
		generalButton.button_pressed = false
		audioSection.toggle_section(false)
		audioButton.button_pressed = false
		set_button_right_neighbors(null)
	controlsSection.toggle_section(toggled_on)

func _on_audio_button_toggled(toggled_on):
	if toggled_on:
		generalSection.toggle_section(false)
		generalButton.button_pressed = false
		controlsSection.toggle_section(false)
		controlsButton.button_pressed = false
		set_button_right_neighbors(audioSection.musicVolumeSlider)
	audioSection.toggle_section(toggled_on)

func _on_game_logs_button_pressed() -> void:
	gameLogsPanel.show_game_logs()

func _on_logs_panel_back_pressed() -> void:
	gameLogsButton.grab_focus()
