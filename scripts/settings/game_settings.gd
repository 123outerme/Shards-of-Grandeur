extends Resource
class_name GameSettings

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

var defaultInputMap: Dictionary = {}
var save_file = 'game_settings.tres'
static var STORED_ACTIONS = [
	'move_up', 'move_down', 'move_left', 'move_right', 'game_interact',
	'game_decline', 'game_quests', 'game_inventory', 'game_stats', 'game_pause',
	'ui_up', 'ui_down', 'ui_left', 'ui_right', 'ui_accept', 'ui_select'
]

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
	if versionString == '' or versionString == null or get_game_major_version() > get_game_major_version(versionString):
		return VersionDiffs.MAJOR
	
	if get_game_minor_version() > get_game_minor_version(versionString):
		return VersionDiffs.MINOR
	
	if get_game_patch_version() > get_game_patch_version(versionString):
		return VersionDiffs.PATCH
	
	return VersionDiffs.NONE

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
	for action in inputMap.keys(): # assign input map settings
		InputMap.action_erase_events(action)
		for event: InputEvent in inputMap[action]:
			InputMap.action_add_event(action, event)

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

func _filter_input_map(action):
	return action in GameSettings.STORED_ACTIONS
