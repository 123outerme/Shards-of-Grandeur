extends Control
class_name GeneralSection

@export var sectionToggleButton: Button

@onready var virtualKeyboard: VirtualKeyboard = get_node('Control/VirtualKeyboard')

@onready var onscreenKeyboardButton: CheckButton = get_node('Control/VBoxContainer/OnscreenKeyboardControl/OnscreenKeyboardLabel/OnscreenKeyboardButton')
@onready var screenShakeButton: CheckButton = get_node('Control/VBoxContainer/ScreenShakeControl/ScreenShakeLabel/ScreenShakeButton')
@onready var runToggleButton: CheckButton = get_node('Control/VBoxContainer/RunToggleControl/RunToggleLabel/RunToggleButton')
@onready var vsyncButton: CheckButton = get_node('Control/VBoxContainer/VSyncControl/VsyncLabel/VsyncButton')
@onready var framerateSpinBox: SpinBox = get_node('Control/VBoxContainer/FramerateControl/FramerateLabel/FramerateSpinBox')

# Called when the node enters the scene tree for the first time.
func _ready():
	virtualKeyboard.enabled = SettingsHandler.gameSettings.useVirtualKeyboard

func toggle_section(toggle: bool):
	visible = toggle
	if toggle:
		onscreenKeyboardButton.button_pressed = SettingsHandler.gameSettings.useVirtualKeyboard
		screenShakeButton.button_pressed = SettingsHandler.gameSettings.screenShake
		runToggleButton.button_pressed = SettingsHandler.gameSettings.toggleRun
		vsyncButton.button_pressed = SettingsHandler.gameSettings.vsync
		framerateSpinBox.value = SettingsHandler.gameSettings.framerate
		
		onscreenKeyboardButton.focus_neighbor_left = onscreenKeyboardButton.get_path_to(sectionToggleButton)
		sectionToggleButton.focus_neighbor_right = sectionToggleButton.get_path_to(onscreenKeyboardButton)
		screenShakeButton.focus_neighbor_left = screenShakeButton.get_path_to(sectionToggleButton)
		runToggleButton.focus_neighbor_left = runToggleButton.get_path_to(sectionToggleButton)
		vsyncButton.focus_neighbor_left = vsyncButton.get_path_to(sectionToggleButton)
		framerateSpinBox.focus_neighbor_left = framerateSpinBox.get_path_to(sectionToggleButton)

func _on_onscreen_keyboard_button_toggled(toggled_on):
	SettingsHandler.gameSettings.useVirtualKeyboard = toggled_on
	virtualKeyboard.enabled = SettingsHandler.gameSettings.useVirtualKeyboard
	if virtualKeyboard.visible and not virtualKeyboard.enabled:
		virtualKeyboard.hide_keyboard()

func _on_screen_shake_button_toggled(toggled_on):
	SettingsHandler.gameSettings.screenShake = toggled_on

func _on_run_toggle_button_toggled(toggled_on):
	SettingsHandler.gameSettings.toggleRun = toggled_on

func _on_vsync_button_toggled(toggled_on):
	SettingsHandler.gameSettings.vsync = toggled_on
	SettingsHandler.gameSettings.apply_vsync()

func _on_framerate_spin_box_value_changed(value):
	var framerate = min(144, max(30, value)) # bound between 144 and 30
	
	SettingsHandler.gameSettings.framerate = framerate
	SettingsHandler.gameSettings.apply_framerate()

func _on_virtual_keyboard_backspace_pressed():
	framerateSpinBox.value = floori(framerateSpinBox.value / 10)

func _on_virtual_keyboard_enter_pressed():
	framerateSpinBox.value = min(144, max(30, framerateSpinBox.value))
	_on_framerate_spin_box_value_changed(framerateSpinBox.value)
	vsyncButton.grab_focus()

func _on_virtual_keyboard_key_pressed(character):
	var numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
	var charIdx = numbers.find(character)
	#print(charIdx)
	if charIdx != -1:
		var value = framerateSpinBox.value * 10
		value += charIdx
		framerateSpinBox.value = value

func _on_virtual_keyboard_keyboard_hidden():
	framerateSpinBox.value = min(144, max(30, framerateSpinBox.value))
	_on_framerate_spin_box_value_changed(framerateSpinBox.value)
	vsyncButton.grab_focus()

func _on_framerate_spin_box_focus_entered():
	print('debug focus framerate spin box')
