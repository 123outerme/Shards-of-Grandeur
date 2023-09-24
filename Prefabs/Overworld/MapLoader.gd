extends Node2D

var mapInstance: Node = null

@onready var player: PlayerController = get_node_or_null("../Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	SaveHandler.load_data()
	load_map(PlayerResources.playerInfo.map)
	if player != null:
		PlayerFinder.player = player
	else:
		player = PlayerFinder.player

func entered_warp(newMapName, newMapPos, isUnderground):
	player.position = newMapPos
	player.set_talk_npc(null)
	PlayerResources.playerInfo.map = newMapName
	load_map(newMapName)

func load_map(mapName):
	SaveHandler.save_data()
	if mapInstance != null:
		mapInstance.queue_free()
	var mapScene = load("res://Prefabs/Maps/" + mapName + ".tscn")
	mapInstance = mapScene.instantiate()
	add_child.call_deferred(mapInstance)
	SaveHandler.call_deferred("load_data")
	call_deferred("reparent_player")

func reparent_player():
	player.get_parent().remove_child(player)
	var tilemap = get_node('/' + mapInstance.get_path().get_concatenated_names().c_escape() + '/TileMap')
	tilemap.add_child(player)
	player = get_node('/' + tilemap.get_path().get_concatenated_names().c_escape() + '/Player')
	PlayerFinder.player = player
