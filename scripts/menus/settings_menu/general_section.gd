extends Control
class_name GeneralSection

@export var sectionToggleButton: Button

var framerate: int = 60
var prevFramerate: int = 60
var numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
var allFramerateTextSelected: bool = false

@onready var virtualKeyboard: VirtualKeyboard = get_node('Control/VirtualKeyboard')

@onready var onscreenKeyboardButton: CheckButton = get_node('Control/VBoxContainer/OnscreenKeyboardControl/OnscreenKeyboardLabel/OnscreenKeyboardButton')
@onready var screenShakeButton: CheckButton = get_node('Control/VBoxContainer/ScreenShakeControl/ScreenShakeLabel/ScreenShakeButton')
@onready var runToggleButton: CheckButton = get_node('Control/VBoxContainer/RunToggleControl/RunToggleLabel/RunToggleButton')
@onready var vsyncButton: CheckButton = get_node('Control/VBoxContainer/VSyncControl/VsyncLabel/VsyncButton')
@onready var deadzoneSlider: HSlider = get_node('Control/VBoxContainer/DeadzoneControl/DeadzoneLabel/DeadzoneSlider')
@onready var framerateLineEdit: LineEdit = get_node('Control/VBoxContainer/FramerateControl/FramerateLabel/FramerateLineEdit')

# Called when the node enters the scene tree for the first time.
func _ready():
	virtualKeyboard.enabled = SettingsHandler.gameSettings.useVirtualKeyboard

func toggle_section(toggle: bool):
	visible = toggle
	framerate = SettingsHandler.gameSettings.framerate
	prevFramerate = framerate
	if toggle:
		onscreenKeyboardButton.button_pressed = SettingsHandler.gameSettings.useVirtualKeyboard
		screenShakeButton.button_pressed = SettingsHandler.gameSettings.screenShake
		runToggleButton.button_pressed = SettingsHandler.gameSettings.toggleRun
		vsyncButton.button_pressed = SettingsHandler.gameSettings.vsync
		deadzoneSlider.value = roundi(SettingsHandler.gameSettings.deadzone * 100)
		framerateLineEdit.text = String.num(framerate) + ' FPS'
		
		onscreenKeyboardButton.focus_neighbor_left = onscreenKeyboardButton.get_path_to(sectionToggleButton)
		sectionToggleButton.focus_neighbor_right = sectionToggleButton.get_path_to(onscreenKeyboardButton)
		screenShakeButton.focus_neighbor_left = screenShakeButton.get_path_to(sectionToggleButton)
		runToggleButton.focus_neighbor_left = runToggleButton.get_path_to(sectionToggleButton)
		vsyncButton.focus_neighbor_left = vsyncButton.get_path_to(sectionToggleButton)
		framerateLineEdit.focus_neighbor_left = framerateLineEdit.get_path_to(sectionToggleButton)

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

func _on_virtual_keyboard_backspace_pressed():
	if allFramerateTextSelected:
		framerateLineEdit.text = ''
		allFramerateTextSelected = false
	else:
		framerate = floori(framerate / 10)
		framerateLineEdit.text = String.num(framerate)

func _on_virtual_keyboard_enter_pressed():
	_on_framerate_line_edit_text_submitted(framerateLineEdit.text)

func _on_virtual_keyboard_key_pressed(character):
	var charIdx = numbers.find(character)
	#print(charIdx)
	if charIdx != -1:
		if allFramerateTextSelected:
			framerate = charIdx
			allFramerateTextSelected = false
		else:
			framerate *= 10
			framerate += charIdx
		framerateLineEdit.text = String.num(framerate)

func _on_virtual_keyboard_keyboard_hidden():
	framerateLineEdit.text = String.num(framerate) + ' FPS'
	vsyncButton.grab_focus()

func _on_framerate_line_edit_focus_entered():
	framerateLineEdit.text = String.num(framerate)
	allFramerateTextSelected = true

func _on_framerate_line_edit_focus_exited():
	_on_framerate_line_edit_text_submitted(framerateLineEdit.text)

func _on_framerate_line_edit_text_changed(new_text: String):
	if new_text.is_valid_int():
		framerate = min(144, max(30, new_text.to_int())) # bound between 144 and 30
		SettingsHandler.gameSettings.framerate = framerate

func _on_framerate_line_edit_text_submitted(new_text):
	if new_text == '':
		new_text = '60' # default: 60 FPS
	if new_text.is_valid_int():
		framerate = min(144, max(30, new_text.to_int())) # bound between 144 and 30
	else:
		framerate = prevFramerate
	SettingsHandler.gameSettings.framerate = framerate
	SettingsHandler.gameSettings.apply_framerate()
	framerateLineEdit.text = String.num(framerate) + ' FPS'
	prevFramerate = framerate
	deadzoneSlider.grab_focus()

func _on_deadzone_slider_focus_exited():
	SettingsHandler.gameSettings.deadzone = deadzoneSlider.value / 100.0
	print(SettingsHandler.gameSettings.deadzone)
	SettingsHandler.gameSettings.apply_deadzone()
