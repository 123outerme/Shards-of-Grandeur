extends Node

var previousScene

# Called when the node enters the scene tree for the first time.
func _ready():
	previousScene = get_node_or_null("/root/MainMenu")

func load_overworld():
	var overworldScene = load("res://GameScenes/Overworld.tscn")
	var overworldInstance = overworldScene.instantiate()
	add_sibling.call_deferred(overworldInstance)
	previousScene.queue_free()
	previousScene = overworldInstance
	
func load_main_menu():
	var mainMenuScene = load("res://GameScenes/MainMenu.tscn")
	var mainMenuInstance = mainMenuScene.instantiate()
	add_sibling.call_deferred(mainMenuInstance)
	previousScene.queue_free()
	previousScene = mainMenuInstance
