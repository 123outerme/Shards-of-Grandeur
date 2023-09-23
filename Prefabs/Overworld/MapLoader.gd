extends Node2D

var mapInstance = null

@onready var SaveHandler: SaveHandler = get_node("/root/SaveHandler")
@onready var PlayerResources = get_node("/root/PlayerResources")

# Called when the node enters the scene tree for the first time.
func _ready():
	SaveHandler.load_data()
	load_map(PlayerResources.playerInfo.map)
	pass # Replace with function body.

func entered_warp(newMapName, newMapPos, isUnderground):
	var player = get_node("/root/Overworld/Player")
	player.position = newMapPos
	PlayerResources.playerInfo.map = newMapName
	load_map(newMapName)
	pass

func load_map(mapName):
	SaveHandler.save_data()
	if mapInstance != null:
		mapInstance.queue_free()
	var mapScene = load("res://Prefabs/Maps/" + mapName + ".tscn")
	mapInstance = mapScene.instantiate()
	add_child.call_deferred(mapInstance)
	SaveHandler.call_deferred("load_data")
	pass
