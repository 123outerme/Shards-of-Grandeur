extends Resource
class_name GameSettings

@export var inputMap: Dictionary = {}
@export var volume: float = 0.5

var defaultInputMap: Dictionary = {}
var save_file = 'game_settings.tres'
var stored_actions = [
	'move_up', 'move_down', 'move_left', 'move_right', 'game_interact',
	'game_decline', 'game_quests', 'game_inventory', 'game_stats', 'game_pause',
	'ui_up', 'ui_down', 'ui_left', 'ui_right', 'ui_accept', 'ui_select'
]

func _init(
	i_inputMap: Dictionary = {},
	i_volume = 0.5
):
	inputMap = i_inputMap.duplicate()
	volume = i_volume
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

func apply_from_stored_inputs():
	for action in inputMap.keys(): # assign input map settings
		InputMap.action_erase_events(action)
		for event in inputMap[action]:
			InputMap.action_add_event(action, event)

func load_data(save_path):
	var data = null
	if ResourceLoader.exists(save_path + save_file):
		data = load(save_path + save_file)
		if data != null:
			return data
	return data

func save_data(save_path, data):
	var err = ResourceSaver.save(data, save_path + save_file)
	if err != 0:
		printerr("GameSettings ResourceSaver error: ", err)

func _filter_input_map(action):
	return action in stored_actions
