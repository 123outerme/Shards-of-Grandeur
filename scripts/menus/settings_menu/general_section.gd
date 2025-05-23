extends Control
class_name GeneralSection

signal resize_complete(ok: bool)

@export var sectionToggleButton: Button

const windowSizeOptions: Dictionary[int, Vector2i] = {
	0: Vector2i(1280, 720),
	1: Vector2i(1920, 1080)
}
const resizeWaitTime: float = 15

const MAX_FRAMERATE: int = 144
const MAX_MOBILE_FRAMERATE = 90
const MIN_FRAMERATE: int = 30

var windowSizeOptionsMenu: PopupMenu = null
var waitingForResizeConfirm: bool = false
var resizeAccum: float = 0
var previousWindowSize: Vector2i = windowSizeOptions[0]

var prevFullscreen: bool = false

var framerate: int = 60
var prevFramerate: int = 60
var numbers = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
var allFramerateTextSelected: bool = false

@onready var virtualKeyboard: VirtualKeyboard = get_node('Control/VirtualKeyboard')

@onready var onscreenKeyboardButton: CheckButton = get_node('Control/VBoxContainer/OnscreenKeyboardControl/OnscreenKeyboardLabel/OnscreenKeyboardButton')

@onready var runToggleControl: Control = get_node('Control/VBoxContainer/RunToggleControl')
@onready var runToggleButton: CheckButton = get_node('Control/VBoxContainer/RunToggleControl/RunToggleLabel/RunToggleButton')

@onready var screenShakeButton: CheckButton = get_node('Control/VBoxContainer/ScreenShakeControl/ScreenShakeLabel/ScreenShakeButton')

@onready var bgMotionButton: CheckButton = get_node('Control/VBoxContainer/BackgroundMotionControl/BackgroundMotionLabel/BackgroundMotionButton')

@onready var battleAnimsButton: CheckButton = get_node('Control/VBoxContainer/BattleAnimsControl/BattleAnimsLabel/BattleAnimsButton')

@onready var touchJoystickTypeControl: Control = get_node('Control/VBoxContainer/TouchJoystickTypeControl')
@onready var touchJoystickTypeToggleButton: Button = get_node('Control/VBoxContainer/TouchJoystickTypeControl/TouchJoystickTypeLabel/CenterButtonHBox/TouchJoystickTypeToggleButton')

@onready var touchJoystickDeadzoneControl: Control = get_node('Control/VBoxContainer/TouchJoystickDeadzoneControl')
@onready var touchJoystickDeadzoneSlider: HSlider = get_node('Control/VBoxContainer/TouchJoystickDeadzoneControl/TouchDeadzoneLabel/TouchDeadzoneSlider')

@onready var windowControl: Control = get_node('Control/VBoxContainer/WindowControl')
@onready var windowOptionsButton: MenuButton = get_node('Control/VBoxContainer/WindowControl/WindowLabel/WindowOptionsButton')
@onready var windowMenuBtnLabel: RichTextLabel = get_node('Control/VBoxContainer/WindowControl/WindowLabel/WindowOptionsButton/WindowMenuBtnLabel')

@onready var fullscreenControl: Control = get_node('Control/VBoxContainer/FullscreenControl')
@onready var fullscreenButton: CheckButton = get_node('Control/VBoxContainer/FullscreenControl/FullscreenLabel/FullscreenButton')

@onready var vsyncControl: Control = get_node('Control/VBoxContainer/VSyncControl')
@onready var vsyncButton: CheckButton = get_node('Control/VBoxContainer/VSyncControl/VsyncLabel/VsyncButton')

@onready var deadzoneSlider: HSlider = get_node('Control/VBoxContainer/DeadzoneControl/DeadzoneLabel/DeadzoneSlider')
@onready var framerateLineEdit: LineEdit = get_node('Control/VBoxContainer/FramerateControl/FramerateLabel/FramerateLineEdit')

@onready var itemConfirmPanel: ItemConfirmPanel = get_node('ItemConfirmPanel')

# Called when the node enters the scene tree for the first time.
func _ready():
	virtualKeyboard.enabled = SettingsHandler.gameSettings.useVirtualKeyboard
	framerateLineEdit.virtual_keyboard_enabled = not SettingsHandler.gameSettings.useVirtualKeyboard
	windowSizeOptionsMenu = windowOptionsButton.get_popup()
	for key in windowSizeOptions.keys():
		windowSizeOptionsMenu.add_radio_check_item(String.num_int64(windowSizeOptions[key].x) + ' x ' + String.num_int64(windowSizeOptions[key].y), key)
	if not windowSizeOptionsMenu.id_pressed.is_connected(_on_window_option_chosen):
		windowSizeOptionsMenu.id_pressed.connect(_on_window_option_chosen)
	
	if SettingsHandler.isMobile:
		runToggleControl.visible = false
		windowControl.visible = false
		fullscreenControl.visible = false
		vsyncControl.visible = false
		touchJoystickTypeControl.visible = true
		touchJoystickDeadzoneControl.visible = true
		onscreenKeyboardButton.focus_neighbor_bottom = onscreenKeyboardButton.get_path_to(screenShakeButton)
		screenShakeButton.focus_neighbor_top = screenShakeButton.get_path_to(onscreenKeyboardButton)
		deadzoneSlider.focus_neighbor_bottom = deadzoneSlider.get_path_to(touchJoystickTypeToggleButton)
		framerateLineEdit.focus_neighbor_top = framerateLineEdit.get_path_to(touchJoystickDeadzoneSlider)
	else:
		touchJoystickTypeControl.visible = false
		touchJoystickDeadzoneControl.visible = false

func _exit_tree():
	#if windowSizeOptionsMenu.id_pressed.is_connected(_on_window_option_chosen):
	#	windowSizeOptionsMenu.id_pressed.disconnect(_on_window_option_chosen)
	pass

func _process(delta):
	if waitingForResizeConfirm:
		resizeAccum += delta
		var timeLeft: int = ceili(resizeWaitTime - resizeAccum)
		itemConfirmPanel.descriptionLabel.text = '[center]Is this size OK? Resetting in ' + \
				String.num_int64(timeLeft) + ' second' + ('s' if timeLeft != 1 else '') + \
				'.[/center]'
		if resizeAccum >= resizeWaitTime:
			itemConfirmPanel._on_no_button_pressed()
		
func toggle_section(toggle: bool):
	visible = toggle
	framerate = SettingsHandler.gameSettings.framerate
	prevFramerate = framerate
	if toggle:
		onscreenKeyboardButton.button_pressed = SettingsHandler.gameSettings.useVirtualKeyboard
		runToggleButton.button_pressed = SettingsHandler.gameSettings.toggleRun
		screenShakeButton.button_pressed = SettingsHandler.gameSettings.screenShake
		bgMotionButton.button_pressed = SettingsHandler.gameSettings.backgroundMotion
		battleAnimsButton.button_pressed = SettingsHandler.gameSettings.battleAnims
		deadzoneSlider.value = roundi(SettingsHandler.gameSettings.deadzone * 100)
		touchJoystickTypeToggleButton.text = GameSettings.touch_joystick_type_to_string(SettingsHandler.gameSettings.touchJoystickType)
		touchJoystickTypeToggleButton.button_pressed = SettingsHandler.gameSettings.touchJoystickType == GameSettings.TouchJoystickType.FIXED
		touchJoystickDeadzoneSlider.value = roundi(SettingsHandler.gameSettings.touchJoystickDeadzone * 100)
		windowMenuBtnLabel.text = '[center]' + String.num_int64(SettingsHandler.gameSettings.windowSize.x) + ' x ' + String.num_int64(SettingsHandler.gameSettings.windowSize.y) + '[/center]'
		fullscreenButton.button_pressed = SettingsHandler.gameSettings.fullscreen
		vsyncButton.button_pressed = SettingsHandler.gameSettings.vsync
		framerateLineEdit.text = String.num_int64(framerate) + ' FPS'
		
		onscreenKeyboardButton.focus_neighbor_left = onscreenKeyboardButton.get_path_to(sectionToggleButton)
		sectionToggleButton.focus_neighbor_right = sectionToggleButton.get_path_to(onscreenKeyboardButton)
		runToggleButton.focus_neighbor_left = runToggleButton.get_path_to(sectionToggleButton)
		bgMotionButton.focus_neighbor_left = bgMotionButton.get_path_to(sectionToggleButton)
		battleAnimsButton.focus_neighbor_left = battleAnimsButton.get_path_to(sectionToggleButton)
		screenShakeButton.focus_neighbor_left = screenShakeButton.get_path_to(sectionToggleButton)
		touchJoystickTypeToggleButton.focus_neighbor_left = touchJoystickTypeToggleButton.get_path_to(sectionToggleButton)
		windowOptionsButton.focus_neighbor_left = windowOptionsButton.get_path_to(sectionToggleButton)
		fullscreenButton.focus_neighbor_left = fullscreenButton.get_path_to(sectionToggleButton)
		vsyncButton.focus_neighbor_left = vsyncButton.get_path_to(sectionToggleButton)
		framerateLineEdit.focus_neighbor_left = framerateLineEdit.get_path_to(sectionToggleButton)
	
func _on_onscreen_keyboard_button_toggled(toggled_on):
	SettingsHandler.gameSettings.useVirtualKeyboard = toggled_on
	SettingsHandler.settings_changed.emit()
	virtualKeyboard.enabled = SettingsHandler.gameSettings.useVirtualKeyboard
	framerateLineEdit.virtual_keyboard_enabled = not virtualKeyboard.enabled
	if virtualKeyboard.visible and not virtualKeyboard.enabled:
		virtualKeyboard.hide_keyboard()

func _on_run_toggle_button_toggled(toggled_on):
	SettingsHandler.gameSettings.toggleRun = toggled_on
	SettingsHandler.settings_changed.emit()

func _on_screen_shake_button_toggled(toggled_on):
	SettingsHandler.gameSettings.screenShake = toggled_on
	SettingsHandler.settings_changed.emit()

func _on_background_motion_button_toggled(toggled_on: bool) -> void:
	SettingsHandler.gameSettings.backgroundMotion = toggled_on
	SettingsHandler.settings_changed.emit()

func _on_battle_anims_button_toggled(toggled_on: bool) -> void:
	SettingsHandler.gameSettings.battleAnims = toggled_on
	SettingsHandler.settings_changed.emit()

func _on_fullscreen_button_toggled(toggled_on):
	prevFullscreen = SettingsHandler.gameSettings.fullscreen
	previousWindowSize = SettingsHandler.gameSettings.windowSize
	if toggled_on == prevFullscreen:
		return
	SettingsHandler.gameSettings.fullscreen = toggled_on
	SettingsHandler.gameSettings.apply_fullscreen(get_viewport())
	itemConfirmPanel.title = 'Window Resized'
	itemConfirmPanel.description = 'Is this size OK? Resetting in ' + String.num_int64(ceili(resizeWaitTime)) + ' seconds.'
	itemConfirmPanel.load_item_confirm_panel()
	resizeAccum = 0
	waitingForResizeConfirm = true

func _on_vsync_button_toggled(toggled_on):
	SettingsHandler.gameSettings.vsync = toggled_on
	SettingsHandler.gameSettings.apply_vsync()
	SettingsHandler.settings_changed.emit()

func _on_virtual_keyboard_backspace_pressed():
	if allFramerateTextSelected:
		framerateLineEdit.text = ''
		allFramerateTextSelected = false
	else:
		framerate = floori(framerate / 10)
		framerateLineEdit.text = String.num_int64(framerate)

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
		framerateLineEdit.text = String.num_int64(framerate)

func _on_virtual_keyboard_keyboard_hidden():
	framerateLineEdit.text = String.num_int64(framerate) + ' FPS'
	vsyncButton.grab_focus()

func _on_framerate_line_edit_focus_entered():
	framerateLineEdit.text = String.num_int64(framerate)
	allFramerateTextSelected = true

func _on_framerate_line_edit_focus_exited():
	_on_framerate_line_edit_text_submitted(framerateLineEdit.text)

func _on_framerate_line_edit_text_changed(new_text: String):
	if new_text.is_valid_int():
		var maxFramerate: int = MAX_FRAMERATE
		if SettingsHandler.isMobile:
			maxFramerate = MAX_MOBILE_FRAMERATE
		framerate = min(maxFramerate, max(MIN_FRAMERATE, new_text.to_int())) # bound between 144 and 30
		SettingsHandler.gameSettings.framerate = framerate
		SettingsHandler.settings_changed.emit()

func _on_framerate_line_edit_text_submitted(new_text):
	if new_text == '':
		new_text = '60' # default: 60 FPS
	if new_text.is_valid_int():
		var maxFramerate: int = MAX_FRAMERATE
		if SettingsHandler.isMobile:
			maxFramerate = MAX_MOBILE_FRAMERATE
		framerate = min(maxFramerate, max(MIN_FRAMERATE, new_text.to_int())) # bound between 144 and 30
	else:
		framerate = prevFramerate
	SettingsHandler.gameSettings.framerate = framerate
	SettingsHandler.gameSettings.apply_framerate()
	SettingsHandler.settings_changed.emit()
	framerateLineEdit.text = String.num_int64(framerate) + ' FPS'
	prevFramerate = framerate
	deadzoneSlider.grab_focus()

func _on_deadzone_slider_focus_exited():
	SettingsHandler.gameSettings.deadzone = deadzoneSlider.value / 100.0
	#print(SettingsHandler.gameSettings.deadzone)
	SettingsHandler.gameSettings.apply_deadzone()
	SettingsHandler.settings_changed.emit()

func _on_window_option_chosen(id):
	prevFullscreen = SettingsHandler.gameSettings.fullscreen
	previousWindowSize = SettingsHandler.gameSettings.windowSize
	if windowSizeOptions[id] == previousWindowSize:
		return
	SettingsHandler.gameSettings.windowSize = windowSizeOptions[id]
	SettingsHandler.gameSettings.apply_window_size(get_viewport())
	itemConfirmPanel.title = 'Window Resized'
	itemConfirmPanel.description = 'Is this size OK? Resetting in ' + String.num_int64(ceili(resizeWaitTime)) + ' seconds.'
	itemConfirmPanel.load_item_confirm_panel()
	resizeAccum = 0
	waitingForResizeConfirm = true

func _on_item_confirm_panel_confirm_option(yes):
	if yes:
		windowMenuBtnLabel.text = '[center]' + String.num_int64(SettingsHandler.gameSettings.windowSize.x) + ' x ' + String.num_int64(SettingsHandler.gameSettings.windowSize.y) + '[/center]'
		SettingsHandler.settings_changed.emit()
	else:
		SettingsHandler.gameSettings.fullscreen = prevFullscreen
		SettingsHandler.gameSettings.windowSize = previousWindowSize
		# swich the fullscreen toggle button back (doesn't open another confirm panel)
		fullscreenButton.button_pressed = prevFullscreen
		SettingsHandler.gameSettings.apply_window_size(get_viewport())
		SettingsHandler.gameSettings.apply_fullscreen(get_viewport())
	resizeAccum = 0
	waitingForResizeConfirm = false
	windowOptionsButton.grab_focus()

func _on_touch_joystick_type_toggle_button_toggled(toggled_on: bool):
	SettingsHandler.gameSettings.touchJoystickType = GameSettings.TouchJoystickType.FIXED if toggled_on else GameSettings.TouchJoystickType.FLOATING
	touchJoystickTypeToggleButton.text = GameSettings.touch_joystick_type_to_string(SettingsHandler.gameSettings.touchJoystickType)
	SettingsHandler.settings_changed.emit()

func _on_touch_deadzone_slider_focus_exited() -> void:
	SettingsHandler.gameSettings.touchJoystickDeadzone = touchJoystickDeadzoneSlider.value / 100.0
	print(SettingsHandler.gameSettings.touchJoystickDeadzone)
	SettingsHandler.settings_changed.emit()

func _on_deadzone_slider_drag_ended(value_changed: bool) -> void:
	_on_deadzone_slider_focus_exited()

func _on_touch_deadzone_slider_drag_ended(value_changed: bool) -> void:
	_on_touch_deadzone_slider_focus_exited()
