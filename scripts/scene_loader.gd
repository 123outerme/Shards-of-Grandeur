extends Node

var currentScene
var unpauseExcludedMover: Node2D = null
var mapLoader: MapLoader = null
var audioHandler: AudioHandler = null
var cutscenePlayer: CutscenePlayer = null
var curMapEntry: MapEntry = null

# Called when the node enters the scene tree for the first time.
func _ready():
	currentScene = get_tree().get_first_node_in_group('Scenes')

func load_game(saveFolder: String = 'save'):
	PlayerResources.saveFolder = saveFolder
	if SaveHandler.is_save_in_battle(saveFolder):
		PlayerResources.battleSaveFolder = saveFolder
		load_battle(saveFolder)
	else:
		load_overworld(saveFolder)

func load_battle(saveFolder: String = ''):
	if saveFolder != '':
		SaveHandler.load_data(saveFolder)
	call_deferred('load_scene', preload("res://gamescenes/battle.tscn"))

func load_overworld(saveFolder: String = ''):
	if saveFolder != '':
		SaveHandler.load_data(saveFolder)
	call_deferred('load_scene', preload("res://gamescenes/overworld.tscn"))
	
func load_main_menu():
	call_deferred('load_scene', preload("res://gamescenes/main_menu.tscn"))
	PlayerResources.timeSinceLastLoad = -1

func load_scene(scene):
	var sceneInstance = scene.instantiate()
	get_tree().root.call_deferred('add_child', sceneInstance)
	if currentScene != null:
		mapLoader = null
		currentScene.queue_free()
	currentScene = sceneInstance

func pause_autonomous_movers():
	var movers = get_tree().get_nodes_in_group('AutonomousMove')
	for mover in movers:
		if mover.has_method('pause_movement'):
			mover.pause_movement()
		else:
			printerr('Autonomous mover ', mover.name, ' has no pause_movement function!!')

func unpause_autonomous_movers():
	var movers = get_tree().get_nodes_in_group('AutonomousMove')
	for mover in movers:
		if mover.has_method('unpause_movement'):
			if mover != unpauseExcludedMover:
				mover.unpause_movement()
		else:
			printerr('Autonomous mover ', mover.name, ' has no unpause_movement function!!')
	unpauseExcludedMover = null
