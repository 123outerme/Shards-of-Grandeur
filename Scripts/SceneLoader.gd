extends Node

var currentScene
var unpauseExcludedMover: Node2D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	currentScene = get_tree().get_first_node_in_group('Scenes')

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
		currentScene.queue_free()
	currentScene = sceneInstance

func pause_autonomous_movers():
	var movers = get_tree().get_nodes_in_group('AutonomousMove')
	for mover in movers:
		if mover.has_method('pause_movement'):
			mover.pause_movement()

func unpause_autonomous_movers():
	var movers = get_tree().get_nodes_in_group('AutonomousMove')
	for mover in movers:
		if mover.has_method('unpause_movement') and mover != unpauseExcludedMover:
			mover.unpause_movement()
	unpauseExcludedMover = null
