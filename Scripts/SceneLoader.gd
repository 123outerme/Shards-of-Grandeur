extends Node

var currentScene
var unpauseExcludedMover: Node2D = null
var mapLoader: MapLoader = null

# Called when the node enters the scene tree for the first time.
func _ready():
	currentScene = get_tree().get_first_node_in_group('Scenes')

func load_game():
	if SaveHandler.is_save_in_battle():
		load_battle()
	else:
		load_overworld()

func load_battle():
	load_scene(preload("res://GameScenes/Battle.tscn"))

func load_overworld():
	load_scene(preload("res://GameScenes/Overworld.tscn"))
	
func load_main_menu():
	load_scene(preload("res://GameScenes/MainMenu.tscn"))
	
func load_scene(scene):
	var sceneInstance = scene.instantiate()
	add_sibling.call_deferred(sceneInstance)
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
