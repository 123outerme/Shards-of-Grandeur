extends Node
class_name MapLoader

var mapInstance: Node = null
var mapNavReady: bool = false
var mapEntry: MapEntry = null

@onready var player: PlayerController = get_node_or_null("../Player")

# Called when the node enters the scene tree for the first time.
func _ready():
	NavigationServer2D.map_changed.connect(_nav_map_changed)
	SceneLoader.mapLoader = self
	SaveHandler.load_data()
	if PlayerResources.playerInfo.combatant.downed:
		load_recover_map()
	else:
		load_map(PlayerResources.playerInfo.map)
	if player != null:
		PlayerFinder.player = player
	else:
		player = PlayerFinder.player

func entered_warp(newMapName: String, newMapPos: Vector2, warpPos: Vector2, isUnderground: bool = false, useVOffset: bool = false, useHOffset: bool = false):
	player.cam.fade_out(_fade_out_complete, 0.25)
	player.disableMovement = true
	player.collider.set_deferred('disabled', true)
	await get_tree().create_timer(0.25).timeout
	if useVOffset:
		newMapPos.y -= warpPos.y - player.position.y
	if useHOffset:
		newMapPos.x -= warpPos.x - player.position.x
	player.position = newMapPos
	player.set_talk_npc(null)
	PlayerResources.playerInfo.map = newMapName
	SceneLoader.cutscenePlayer.isFadedOut = false
	SceneLoader.cutscenePlayer.end_cutscene(true)
	if player.holdingCamera:
		player.snap_camera_back_to_player(0)
	for spawner in get_tree().get_nodes_in_group('EnemySpawner'):
		spawner.delete_enemy()
	load_map(newMapName)

func load_recover_map():
	var recoveryMapEntry: MapEntry = get_map_entry_for_map_name(PlayerResources.playerInfo.recoverMap)
	PlayerResources.playerInfo.combatant.downed = false
	player.disableMovement = true
	player.get_collider().set_deferred('disabled', true)
	if recoveryMapEntry != null:
		player.position = recoveryMapEntry.recoverPosition
		PlayerResources.playerInfo.position = recoveryMapEntry.recoverPosition
		load_map(PlayerResources.playerInfo.recoverMap)
	else:
		printerr('Error: Recovery map not found!!')
		load_map(PlayerResources.playerInfo.map)

func load_map(mapName: String):
	#destroy_overworld_enemies()
	PlayerResources.playerInfo.map = mapName
	mapNavReady = false
	player.disableMovement = true
	player.useTeleportStone = null
	if mapInstance != null:
		mapInstance.queue_free()
	var mapScene = null
	# if this act has a specific map for this act, load it
	var newMapEntry = get_map_entry_for_map_name(mapName)
	if newMapEntry != null:
		if newMapEntry.isRecoverLocation:
			PlayerResources.playerInfo.recoverMap = mapName
		mapScene = load(newMapEntry.get_map_path())
		mapEntry = newMapEntry
		SceneLoader.curMapEntry = mapEntry
	if mapScene == null:
		printerr('Map ', mapName, ' could not be found!')
		get_tree().quit(1)
		return
	SaveHandler.save_data()
	mapInstance = mapScene.instantiate()
	mapInstance.map_loaded.connect(_map_loaded)
	add_child.call_deferred(mapInstance)
	SaveHandler.call_deferred("load_data")
	call_deferred("reparent_player")

func get_map_entry_for_map_name(mapName: String) -> MapEntry:
	if not ResourceLoader.exists("res://gamedata/locations/" + mapName + ".tres"):
		printerr('This world location does not exist: ', mapName)
	var worldLocation = load("res://gamedata/locations/" + mapName + ".tres") as WorldLocation
	if worldLocation != null:
		var entry: MapEntry = worldLocation.get_map_entry_for_location()
		if entry != null:
			return entry
		else:
			printerr('No map entry could be found for: ', mapName)
	else:
		printerr('World location could not be found for: ', mapName)
	return null

func reparent_player():
	player.get_parent().remove_child(player)
	var tilemap = get_node('/' + mapInstance.get_path().get_concatenated_names().c_escape() + '/TileMap')
	tilemap.add_child(player)
	player = get_node('/' + tilemap.get_path().get_concatenated_names().c_escape() + '/Player')
	PlayerFinder.player = player
	player.speed = player.BASE_SPEED # reset running
	SceneLoader.cutscenePlayer.rootNode = tilemap.get_parent()

func destroy_overworld_enemies():
	for spawnerNode in get_tree().get_nodes_in_group('EnemySpawner'):
		if spawnerNode.has_method('delete_enemy'):
			spawnerNode.delete_enemy()

func _fade_out_complete():
	PlayerFinder.player.play_animation('stand')

func _fade_in_complete():
	if not SceneLoader.audioHandler.is_music_already_playing(mapEntry.overworldTheme):
		SceneLoader.audioHandler.cross_fade(mapEntry.overworldTheme, 0.5)
	PlayerFinder.player.collider.set_deferred('disabled', false)
	
func _map_loaded():
	await get_tree().create_timer(0.15).timeout
	player.cam.call_deferred('fade_in', _fade_in_complete, 0.35)
	await get_tree().create_timer(0.15).timeout
	SceneLoader.call_deferred('unpause_autonomous_movers')
	player.collider.set_deferred('disabled', false)
	PlayerFinder.player.set_deferred('disableMovement', player.inCutscene or player.textBox.visible)
	
func _nav_map_changed(_arg):
	mapNavReady = true
