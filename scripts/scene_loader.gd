extends Node

## the current game-scene root node
var currentScene: Node
var unpauseExcludedMover: Node2D = null
var mapLoader: MapLoader = null
var audioHandler: AudioHandler = null
var cutscenePlayer: CutscenePlayer = null
var curMapEntry: MapEntry = null

## if true, debug tools are enabled
var debug: bool = false
var mainGame: MainGame = null

## if true, StoryRequirements will always resolve as "passed"
var ignoreStoryRequirements: bool = false

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
	if PlayerFinder.player != null:
		PlayerFinder.player.overworldTouchControls.touchVirtualJoystick.release_joystick()
	call_deferred('load_scene', preload("res://gamescenes/battle.tscn"))

func load_overworld(saveFolder: String = ''):
	if saveFolder != '':
		SaveHandler.load_data(saveFolder)
		PlayerResources.battleSaveFolder = ''
	call_deferred('load_scene', preload("res://gamescenes/overworld.tscn"))
	
func load_main_menu(initial: bool = false):
	if PlayerFinder.player != null:
		PlayerFinder.player.overworldTouchControls.touchVirtualJoystick.release_joystick()
	call_deferred('load_scene', preload("res://gamescenes/main_menu.tscn"), initial)
	PlayerResources.timeSinceLastLoad = -1

func load_scene(scene, initial: bool = false):
	var sceneInstance = scene.instantiate()
	if initial and sceneInstance is MainMenu:
		sceneInstance.initial = true
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
			printerr('WARNING: Autonomous mover ', mover.name, ' has no pause_movement function!')

func unpause_autonomous_movers():
	var movers = get_tree().get_nodes_in_group('AutonomousMove')
	for mover in movers:
		if mover.has_method('unpause_movement'):
			if mover != unpauseExcludedMover:
				mover.unpause_movement()
		else:
			printerr('WARNING: Autonomous mover ', mover.name, ' has no unpause_movement function!')
	unpauseExcludedMover = null
