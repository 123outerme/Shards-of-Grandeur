extends Node
class_name MainGame

@onready var audioHandler: AudioHandler = get_node('AudioHandler')
@onready var cutscenePlayer: CutscenePlayer = get_node('CutscenePlayer')
@onready var uiRepeatTimer: Timer = get_node('UiRepeatTimer')

var lastRepeatedActionX: String = ''
var lastRepeatedActionY: String = ''
var lastFocusedControl: Control = null

const UI_REPEAT_ACTION_NAMES_X = [
	'ui_repeat_left',
	'ui_repeat_right',
]

const UI_REPEAT_ACTION_NAMES_Y = [
	'ui_repeat_up',
	'ui_repeat_down',
]

const UI_REPEAT_ACTIONS_TO_ACTION: Dictionary = {
	'ui_repeat_up': 'ui_up',
	'ui_repeat_down': 'ui_down',
	'ui_repeat_left': 'ui_left',
	'ui_repeat_right': 'ui_right',
}

func _ready():
	parse_cmdline_args()
	SceneLoader.mainGame = self
	SceneLoader.audioHandler = audioHandler
	SceneLoader.cutscenePlayer = cutscenePlayer
	
	match OS.get_name():
		"Windows", "macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			SettingsHandler.isMobile = false
		"Android":
			SettingsHandler.isMobile = true
	
	if not SettingsHandler.isMobile:
		SettingsHandler.gameSettings.apply_window_size(get_viewport())
		SettingsHandler.gameSettings.apply_fullscreen(get_viewport())
	else:
		SettingsHandler.gameSettings.fullscreen = true
		SettingsHandler.gameSettings.apply_fullscreen(get_viewport())
	
	SceneLoader.load_main_menu()
	get_window().focus_exited.connect(_on_window_focus_exited)
	get_viewport().gui_focus_changed.connect(_on_gui_focus_changed)

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
		# show cursor
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif (event is InputEventJoypadButton or event is InputEventJoypadMotion) and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		# hide cursor
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func _process(_delta):
	for action: String in UI_REPEAT_ACTION_NAMES_X:
		if Input.is_action_pressed(action):
			#print('action pressed: ', action, ' / last repeated: ', lastRepeatedActionX)
			if lastRepeatedActionX != action:
				lastRepeatedActionX = action
				start_repeat(true)
		else:
			#print('action NOT pressed: ', action, ' / last repeated: ', lastRepeatedActionX)
			if lastRepeatedActionX == action:
				create_repeat_press_event(lastRepeatedActionX, false)
				lastRepeatedActionX = ''
				attempt_stop_repeat()

	for action: String in UI_REPEAT_ACTION_NAMES_Y:
		if Input.is_action_pressed(action):
			if lastRepeatedActionY != action:
				lastRepeatedActionY = action
				start_repeat(false)
		elif lastRepeatedActionY == action:
			create_repeat_press_event(lastRepeatedActionY, false)
			lastRepeatedActionY = ''
			attempt_stop_repeat()

func parse_cmdline_args():
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var idx: int = 0
	var nextArgIsDebugVal: bool = false
	while idx < len(args):
		var arg: String = args[idx]
		if (nextArgIsDebugVal and arg == 'true') or arg == '--debug=true' or arg == '-d':
			SceneLoader.debug = true
		if arg == '--debug':
			nextArgIsDebugVal = true
		else:
			nextArgIsDebugVal = false
		idx += 1
	
	if nextArgIsDebugVal:
		SceneLoader.debug = true # if the last arg is just "--debug" then it's set
	#print('debug is ', SceneLoader.debug)

# Solution from https://www.reddit.com/r/godot/comments/x4v5ty/ui_repeated_movement_when_holding_directions_ui/
func start_repeat(changeX: bool):
	#print('Start pressing ', lastRepeatedActionX, ' / ', lastRepeatedActionY)
	if lastRepeatedActionX != '' and changeX:
		create_repeat_press_event(lastRepeatedActionX)
	if lastRepeatedActionY != '' and not changeX:
		create_repeat_press_event(lastRepeatedActionY)
	uiRepeatTimer.wait_time = 0.25
	uiRepeatTimer.start()

func attempt_stop_repeat():
	#print('Stop pressing ', lastRepeatedActionX, ' / ', lastRepeatedActionY)
	if lastRepeatedActionX == '' and lastRepeatedActionY == '':
		uiRepeatTimer.stop()

func _on_ui_repeat_timer_timeout():
	#print('Press ', lastRepeatedActionX, ' / ', lastRepeatedActionY)
	if lastRepeatedActionX != '':
		create_repeat_press_event(lastRepeatedActionX)
	if lastRepeatedActionY != '':
		create_repeat_press_event(lastRepeatedActionY)
	uiRepeatTimer.wait_time = 0.15
	uiRepeatTimer.start()

func create_repeat_press_event(repeatAction: String, downEvent: bool = true):
	#print('create repeat press ', repeatAction)
	var repeatEvent: InputEventAction = InputEventAction.new()
	repeatEvent.action = UI_REPEAT_ACTIONS_TO_ACTION[repeatAction]
	repeatEvent.pressed = downEvent
	Input.parse_input_event(repeatEvent)

func _on_window_focus_exited() -> void:
	# if cursor is hidden and focus is being switched off the game: make it visible again
	if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_gui_focus_changed(control: Control) -> void:
	lastFocusedControl = control
