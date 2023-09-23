extends Node

var previousScene

# Called when the node enters the scene tree for the first time.
func _ready():
	previousScene = get_node("/root/MainMenu")

func load_overworld():
	var overworldScene = load("res://GameScenes/Overworld.tscn")
	var overworldInstance = overworldScene.instantiate()
	add_sibling.call_deferred(overworldInstance)
	previousScene.queue_free()
	
func load_main_menu():
	pass # TODO
