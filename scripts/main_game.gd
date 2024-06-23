extends Node
class_name MainGame

@onready var audioHandler: AudioHandler = get_node('AudioHandler')
@onready var cutscenePlayer: CutscenePlayer = get_node('CutscenePlayer')

func _ready():
	parse_cmdline_args()
	SceneLoader.audioHandler = audioHandler
	SceneLoader.cutscenePlayer = cutscenePlayer
	SettingsHandler.gameSettings.apply_window_size(get_viewport())
	SettingsHandler.gameSettings.apply_fullscreen(get_viewport())
	SceneLoader.load_main_menu()

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
		# show cursor
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif (event is InputEventJoypadButton or event is InputEventJoypadMotion) and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		# hide cursor
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

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
	print('debug is ', SceneLoader.debug)
