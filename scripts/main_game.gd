extends Node
class_name MainGame

@onready var audioHandler: AudioHandler = get_node('AudioHandler')
@onready var cutscenePlayer: CutscenePlayer = get_node('CutscenePlayer')

func _ready():
	SceneLoader.audioHandler = audioHandler
	SceneLoader.cutscenePlayer = cutscenePlayer
	SettingsHandler.gameSettings.apply_window_size(get_viewport())
	SettingsHandler.gameSettings.apply_fullscreen(get_viewport())
	SceneLoader.load_main_menu()
