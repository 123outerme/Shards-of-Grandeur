extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	load_map("TestMap1")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func load_map(mapName):
	var mapScene = load("res://Prefabs/Maps/" + mapName + ".tscn")
	var mapInstance = mapScene.instantiate()
	add_sibling.call_deferred(mapInstance)
