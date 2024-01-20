extends Control
class_name SettingsMenu

signal back_pressed

@onready var backButton: Button = get_node('Panel/VBoxContainer/BackButton')
@onready var controlsButton: Button = get_node('Panel/VBoxContainer/ControlsButton')
@onready var audioButton: Button = get_node('Panel/VBoxContainer/AudioButton')

@onready var controlsSection: ControlsSection = get_node('Panel/SubsectionPanel/ControlsSection')
@onready var audioSection: AudioSection = get_node('Panel/SubsectionPanel/AudioSection')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func toggle_settings_menu(showing: bool):
	visible = showing
	if visible:
		initial_focus()
		controlsSection.toggle_section(true)
	else:
		_on_back_button_pressed()

func initial_focus():
	backButton.grab_focus()

func cancel_changes():
	controlsSection._on_cancel_button_pressed()
	visible = false

func _on_back_button_pressed():
	visible = false
	back_pressed.emit()

func _on_controls_button_toggled(toggled_on):
	controlsSection.toggle_section(toggled_on)

func _on_audio_button_toggled(toggled_on):
	audioSection.toggle_section(toggled_on)
