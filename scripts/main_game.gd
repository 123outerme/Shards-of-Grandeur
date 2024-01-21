extends Node
class_name MainGame

@onready var audioHandler: AudioHandler = get_node('AudioHandler')

func _ready():
	SceneLoader.audioHandler = audioHandler
	SceneLoader.load_main_menu()
