extends Node
class_name MapLoader

signal warp_fadeout_done

const mapIcon: Texture2D = preload('res://graphics/ui/map_icon.png')

var mapInstance: Node = null
var mapNavReady: bool = false
var worldLocation: WorldLocation = null
var mapEntry: MapEntry = null
var usedWarpZone: bool = false
var loading: bool = false

var previousWorldLocationName: String = ''

@onready var player: PlayerController = get_node_or_null("../Player")

static func get_world_location_for_name(mapName: String) -> WorldLocation:
	if not ResourceLoader.exists("res://gamedata/locations/" + mapName + ".tres"):
		printerr('This world location does not exist: ', mapName)
		return null
	return load("res://gamedata/locations/" + mapName + ".tres") as WorldLocation

# Called when the node enters the scene tree for the first time.
func _ready():
	NavigationServer2D.map_changed.connect(_nav_map_changed)
	SceneLoader.mapLoader = self
	if PlayerResources.playerInfo.combatant.downed:
		load_recover_map()
	else:
		load_map(PlayerResources.playerInfo.map)
	if player != null:
		PlayerFinder.player = player
	else:
		player = PlayerFinder.player

func entered_warp(newMapName: String, newMapPos: Vector2, warpPos: Vector2, isUnderground: bool = false, useVOffset: bool = false, useHOffset: bool = false):
	SceneLoader.cutscenePlayer.mark_cutscene_seen()
	usedWarpZone = true
	player.cam.fade_out(_fade_out_complete, 0.25)
	player.disableMovement = true
	player.collider.set_deferred('disabled', true)
	await warp_fadeout_done
	if useVOffset:
		newMapPos.y -= warpPos.y - player.position.y
	if useHOffset:
		newMapPos.x -= warpPos.x - player.position.x
	player.position = newMapPos
	player.set_talk_npc(null)
	PlayerResources.playerInfo.map = newMapName
	SceneLoader.cutscenePlayer.isFadedOut = false
	SceneLoader.cutscenePlayer.end_cutscene(true)
	if player.holdCameraX or player.holdCameraY:
		player.snap_camera_back_to_player(0.1)
	for spawner in get_tree().get_nodes_in_group('EnemySpawner'):
		spawner.delete_enemy()
	load_map(newMapName)

func load_recover_map():
	usedWarpZone = true # not technically a warp zone, but is a mid-game warp (not initial game load)
	var recoveryWorldLocation: WorldLocation = MapLoader.get_world_location_for_name(PlayerResources.playerInfo.recoverMap)
	if recoveryWorldLocation == null:
		printerr('Error: recovery map World Location is null for map name ', PlayerResources.playerInfo.recoverMap)
	var recoveryMapEntry: MapEntry = get_map_entry_for_map_location(recoveryWorldLocation)
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
	#SceneLoader.audioHandler.fade_out_music() # fade out here if not checking for same music when loading a new map
	loading = true
	#destroy_overworld_enemies()
	PlayerResources.playerInfo.map = mapName
	PlayerResources.playerInfo.set_place_visited(mapName)
	mapNavReady = false
	player.disableMovement = true
	player.useTeleportStone = null
	if mapInstance != null:
		mapInstance.queue_free()
	var mapScene = null
	# update the previous world location name
	if worldLocation != null:
		previousWorldLocationName = worldLocation.locationName
	# load the world location with all of the map info
	var newWorldLocation: WorldLocation = MapLoader.get_world_location_for_name(mapName)
	if newWorldLocation == null:
		printerr('Error: World location is null for map name ', mapName)
	# if this act has a specific map for this act, load it
	var newMapEntry = get_map_entry_for_map_location(newWorldLocation)
	if newMapEntry != null:
		if newMapEntry.isRecoverLocation:
			PlayerResources.playerInfo.recoverMap = mapName
		if newMapEntry.overworldTheme != SceneLoader.audioHandler.get_cur_music():
			SceneLoader.audioHandler.fade_out_music()
		''' #multithreaded map loading
		ResourceLoader.load_threaded_request(newMapEntry.get_map_path())
		while ResourceLoader.load_threaded_get_status(newMapEntry.get_map_path()) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass
		mapScene = ResourceLoader.load_threaded_get(newMapEntry.get_map_path())
		#'''
		mapScene = load(newMapEntry.get_map_path())
		worldLocation = newWorldLocation
		mapEntry = newMapEntry
		SceneLoader.curMapEntry = mapEntry
	if mapScene == null:
		printerr('Map ', mapName, ' could not be found!')
		get_tree().quit(1)
		return
	SaveHandler.save_data()
	mapInstance = mapScene.instantiate()
	mapInstance.map_loaded.connect(_map_loaded)
	call_deferred('set_map_to_scene')

func set_map_to_scene():
	if mapInstance.get_parent() == null:
		add_child(mapInstance)
	SaveHandler.call_deferred("load_data")
	call_deferred("reparent_player")

func get_map_entry_for_map_location(location: WorldLocation) -> MapEntry:
	if location != null:
		var entry: MapEntry = location.get_map_entry_for_location()
		if entry != null:
			return entry
		else:
			printerr('No map entry could be found for: ', location.resource_path)
	else:
		printerr('World location was null')
	return null

func reparent_player():
	player.enteredWarpZone = false
	player.get_parent().remove_child(player)
	#await get_tree().process_frame
	var tilemapPath: String = mapInstance.get_path().get_concatenated_names().c_escape()
	var tilemap = get_node_or_null('/' + tilemapPath + '/TilemapRoot')
	if tilemap != null:
		tilemap.add_child(player)
		player = get_node('/' + tilemap.get_path().get_concatenated_names().c_escape() + '/Player')
		PlayerFinder.player = player
	else:
		printerr('TILEMAP NULL error')
	player.speed = player.BASE_SPEED # reset running
	SceneLoader.cutscenePlayer.rootNode = tilemap.get_parent()

func destroy_overworld_enemies():
	for spawnerNode in get_tree().get_nodes_in_group('EnemySpawner'):
		if spawnerNode.has_method('delete_enemy'):
			spawnerNode.delete_enemy()

func show_new_world_location_alert():
	# if the map has changed our world location name:
	if previousWorldLocationName != '' and previousWorldLocationName != worldLocation.locationName:
		# if the player is in a cutscene, wait till it completes to tell the player where they are
		if player.inCutscene:
			await SceneLoader.cutscenePlayer.cutscene_completed
		# show an alert telling the player where they are in the world
		player.cam.show_alert(worldLocation.locationName, mapIcon, null, true)

func _fade_out_complete():
	#print('fade out complete')
	await get_tree().process_frame # wait at least one frame so the fadeout is surely rendered
	warp_fadeout_done.emit()

func _fade_in_complete():
	if not SceneLoader.audioHandler.is_music_already_playing(mapEntry.overworldTheme):
		SceneLoader.audioHandler.fade_in_new_music(mapEntry.overworldTheme, -1, 0)
	loading = false
	#print('fade in complete')
	
func _map_loaded():
	#print('map is loaded')
	await get_tree().create_timer(0.15).timeout
	player.cam.call_deferred('fade_in', _fade_in_complete, 0.35)
	if PlayerFinder.player.sprite.animation == 'teleport':
		PlayerFinder.player.play_animation('stand')
	await get_tree().create_timer(0.15).timeout
	SceneLoader.call_deferred('unpause_autonomous_movers')
	player.collider.set_deferred('disabled', false)
	if usedWarpZone:
		PlayerResources.playerInfo.clear_cutscenes_temp_disabled()
		usedWarpZone = false
	await get_tree().process_frame
	if player.inCutscene or player.textBox.visible:
		PlayerFinder.player.pause_movement()
	else:
		PlayerFinder.player.unpause_movement()
	show_new_world_location_alert()
	
func _nav_map_changed(_arg):
	mapNavReady = true
