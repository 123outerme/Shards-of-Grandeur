extends Node
class_name MapLoader

var mapInstance: Node = null
var mapNavReady: bool = false

@onready var player: PlayerController = get_node_or_null("../Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	NavigationServer2D.map_changed.connect(_nav_map_changed)
	SceneLoader.mapLoader = self
	SaveHandler.load_data()
	load_map(PlayerResources.playerInfo.map)
	if player != null:
		PlayerFinder.player = player
	else:
		player = PlayerFinder.player

func entered_warp(newMapName: String, newMapPos: Vector2, isUnderground: bool = false):
	player.cam.fade_out(_fade_out_complete, 0.25)
	player.disableMovement = true
	player.collider.set_deferred('disabled', true)
	await get_tree().create_timer(0.25).timeout
	player.position = newMapPos
	player.set_talk_npc(null)
	PlayerResources.playerInfo.map = newMapName
	for cutscenePlayer in get_tree().get_nodes_in_group('CutscenePlayer'):
		cutscenePlayer.end_cutscene()
	if player.holdingCamera:
		player.snap_camera_back_to_player(0)
	load_map(PlayerResources.playerInfo.map)

func load_map(mapName):
	#destroy_overworld_enemies()
	SaveHandler.save_data()
	player.disableMovement = true
	mapNavReady = false
	if mapInstance != null:
		mapInstance.queue_free()
	var mapScene = null
	# if this act has a specific map for this act, load it
	if FileAccess.file_exists("res://gamedata/locations/" + mapName + ".tres"):
		var worldLocation = load("res://gamedata/locations/" + mapName + ".tres") as WorldLocation
		if worldLocation != null:
			mapScene = load(worldLocation.get_map_path_for_location())
		else:
			printerr('World location could not be found')
	else:
		printerr('idk lol')
	if mapScene == null:
		printerr('Map ', mapName, ' could not be found!')
		get_tree().quit(1)
		return
	mapInstance = mapScene.instantiate()
	mapInstance.map_loaded.connect(_map_loaded)
	add_child.call_deferred(mapInstance)
	SaveHandler.call_deferred("load_data")
	call_deferred("reparent_player")

func reparent_player():
	player.get_parent().remove_child(player)
	var tilemap = get_node('/' + mapInstance.get_path().get_concatenated_names().c_escape() + '/TileMap')
	tilemap.add_child(player)
	player = get_node('/' + tilemap.get_path().get_concatenated_names().c_escape() + '/Player')
	PlayerFinder.player = player

func destroy_overworld_enemies():
	for spawnerNode in get_tree().get_nodes_in_group('EnemySpawner'):
		if spawnerNode.has_method('delete_enemy'):
			spawnerNode.delete_enemy()

func _fade_out_complete():
	pass

func _fade_in_complete():
	PlayerFinder.player.collider.set_deferred('disabled', false)
	
func _map_loaded():
	await get_tree().create_timer(0.15).timeout
	player.cam.call_deferred('fade_in', _fade_in_complete, 0.35)
	await get_tree().create_timer(0.15).timeout
	SceneLoader.call_deferred('unpause_autonomous_movers')
	PlayerFinder.player.set_deferred('disableMovement', player.inCutscene or player.textBox.visible)
	
func _nav_map_changed(_arg):
	mapNavReady = true
