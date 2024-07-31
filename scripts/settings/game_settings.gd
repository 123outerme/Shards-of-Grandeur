extends Resource
class_name GameSettings

enum TouchJoystickType {
	FIXED = 0,
	FLOATING = 1,
}

@export var inputMap: Dictionary = {}
@export var musicVolume: float = 0.5
@export var sfxVolume: float = 0.5
@export var useVirtualKeyboard: bool = false
@export var screenShake: bool = true
@export var toggleRun: bool = false
@export var vsync: bool = false
@export var deadzone: float = 0.5
@export var framerate: int = 60
@export var windowSize: Vector2i = Vector2i(1280, 720)
@export var fullscreen: bool = false
@export var touchJoystickType: TouchJoystickType = TouchJoystickType.FLOATING

var defaultInputMap: Dictionary = {}
var save_file = 'game_settings.tres'
static var STORED_ACTIONS = [
	'move_up', 'move_down', 'move_left', 'move_right', 'game_interact',
	'game_decline', 'game_quests', 'game_inventory', 'game_stats', 'game_pause',
	'ui_repeat_up', 'ui_repeat_down', 'ui_repeat_left', 'ui_repeat_right',
	'ui_up', 'ui_down', 'ui_left', 'ui_right', 'ui_accept', 'ui_select',
	'game_console'
]

static var UI_TO_MAKE_REPEATING_ACTION_NAMES = [
	'ui_up',
	'ui_down',
	'ui_left',
	'ui_right',
]

static var UI_ACTIONS_TO_REPEAT_ACTION: Dictionary = {
	'ui_up': 'ui_repeat_up',
	'ui_down': 'ui_repeat_down',
	'ui_left': 'ui_repeat_left',
	'ui_right': 'ui_repeat_right',
}

enum VersionDiffs {
	NONE = 0,
	PATCH = 1,
	MINOR = 2,
	MAJOR = 3
}

static func get_game_version() -> String:
	return ProjectSettings.get_setting('application/config/version', '')

static func get_game_major_version(version: String = '') -> int:
	if version == '':
		version = get_game_version()
	return int(version.split('.')[0])

static func get_game_minor_version(version: String = '') -> int:
	if version == '':
		version = get_game_version()
	return int(version.split('.')[1])

static func get_game_patch_version(version: String = '') -> int:
	if version == '':
		version = get_game_version()
	return int(version.split('.')[2])

static func get_version_differences(versionString: String) -> VersionDiffs:
	return get_version_differences_between('', versionString)

static func get_version_differences_between(version1: String, version2: String) -> VersionDiffs:
	if version1 == '':
		version1 = get_game_version()
	
	if version2 == '' or get_game_major_version(version1) > get_game_major_version(version2):
		return VersionDiffs.MAJOR
	
	if get_game_minor_version(version1) > get_game_minor_version(version2):
		return VersionDiffs.MINOR
	
	if get_game_patch_version(version1) > get_game_patch_version(version2):
		return VersionDiffs.PATCH
	
	return VersionDiffs.NONE

static func touch_joystick_type_to_string(t: TouchJoystickType) -> String:
	match t:
		TouchJoystickType.FIXED:
			return 'Fixed'
		TouchJoystickType.FLOATING:
			return 'Floating'
	return 'UNKNOWN'

func _init(
	i_inputMap: Dictionary = {},
	i_musicVolume = 0.5,
	i_sfxVolume = 0.5,
	i_virtualKeyboard = false,
	i_screenShake = true,
	i_toggleRun = false,
	i_vsync = false,
	i_deadzone = 0.5,
	i_framerate = 60,
	i_windowSize = Vector2i(1280, 720),
	i_fullscreen = false,
):
	inputMap = i_inputMap.duplicate()
	musicVolume = i_musicVolume
	sfxVolume = i_sfxVolume
	useVirtualKeyboard = i_virtualKeyboard
	screenShake = i_screenShake
	toggleRun = i_toggleRun
	vsync = i_vsync
	deadzone = i_deadzone
	framerate = i_framerate
	windowSize = i_windowSize
	fullscreen = i_fullscreen
	defaultInputMap = {}
	InputMap.load_from_project_settings() # NOTE side-effect: resets input settings for current execution of game program
	for action in InputMap.get_actions().filter(_filter_input_map):
		defaultInputMap[action] = InputMap.action_get_events(action)
	if inputMap.size() == 0:
		inputMap = defaultInputMap.duplicate() # use default if inputs are empty

func save_controls_from_diffs(diffs: Dictionary):
	for action in diffs.keys():
		inputMap[action] = diffs[action].duplicate()

func restore_default_controls():
	inputMap = defaultInputMap.duplicate()
	apply_from_stored_inputs()

func get_default_controls() -> Dictionary:
	return defaultInputMap

func apply_from_stored_inputs():
	var fixingInputMap: Dictionary = {}
	for action in inputMap.keys(): # assign input map settings
		InputMap.action_erase_events(action)
		for event: InputEvent in inputMap[action]:
			# If this action is one that will be converted to a "repeat" action (for triggering repeated presses in the UI)
			#	(this action is one of the actions that should, and this specific event is a controller event, because keyboard has its own repeat functionality)
			if action in GameSettings.UI_TO_MAKE_REPEATING_ACTION_NAMES and is_event_controller_event(event):
				# if this should be mapped to a "repeat" action, do it
				var repeatAction: String = GameSettings.UI_ACTIONS_TO_REPEAT_ACTION[action]
				InputMap.action_add_event(repeatAction, event)
				if not fixingInputMap.has(action):
					fixingInputMap[action] = [event]
				else:
					fixingInputMap[action].append(event)
			else:
				# otherwise, this is a normal action/event pair, proceed as normal
				InputMap.action_add_event(action, event)
	
	for fixingAction: String in fixingInputMap.keys():
		var repeatAction: String = GameSettings.UI_ACTIONS_TO_REPEAT_ACTION[fixingAction]
		var inputMapEvents: Array[InputEvent] = inputMap[fixingAction]
		for event: InputEvent in fixingInputMap[fixingAction]:
			if event in inputMapEvents:
				inputMapEvents.erase(event)
			if not inputMap.has(repeatAction):
					inputMap[repeatAction] = [event]
			if not (event in inputMap[repeatAction]):
					inputMap[repeatAction].append(event)

func apply_from_diffs(diffs: Dictionary):
	var inputCopy: Dictionary = inputMap.duplicate()
	for action in diffs.keys():
		inputCopy[action] = diffs[action].duplicate()
	
	for action in inputCopy.keys(): # assign input map settings
		InputMap.action_erase_events(action)
		for event in inputCopy[action]:
			InputMap.action_add_event(action, event)

func apply_vsync():
	var vsyncMode = DisplayServer.VSYNC_DISABLED
	if vsync:
		vsyncMode = DisplayServer.VSYNC_ENABLED
	DisplayServer.window_set_vsync_mode(vsyncMode)

func apply_deadzone():
	for action in ['move_up', 'move_down', 'move_left', 'move_right']:
		InputMap.action_set_deadzone(action, deadzone)

func apply_framerate():
	Engine.max_fps = framerate

func apply_window_size(viewport: Viewport):
	viewport.get_window().size = windowSize

func apply_fullscreen(viewport: Viewport):
	viewport.get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
	if not fullscreen:
		apply_window_size(viewport)

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_file):
		data = load(save_path + save_file)
		if data != null:
			return data
	return data

func save_data(save_path, data) -> int:
	var err = ResourceSaver.save(data, save_path + save_file)
	if err != 0:
		printerr("GameSettings ResourceSaver error: ", err)
	return err

func is_event_controller_event(event: InputEvent) -> bool:
	return event is InputEventJoypadButton or event is InputEventJoypadMotion

func _filter_input_map(action: String) -> bool:
	return action in GameSettings.STORED_ACTIONS
