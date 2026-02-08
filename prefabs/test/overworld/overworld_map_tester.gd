extends Node

func _ready() -> void:
	var paths: Array[String] = get_overworld_map_paths('res://prefabs/maps')
	#print(paths)
	#'''
	var forceShownCollisionMaps: Dictionary[String, Array] = {}
	var hasTestTools: Dictionary[String, Array] = {}
	var hasSpawnersQuietingWarnings: Dictionary[String, Array] = {}
	var hasGroundItemsQuietingWarnings: Dictionary[String, Array] = {}
	
	for path: String in paths:
		print('Checking map at ', path)
		var mapPackedScene: PackedScene = load(path)
		var map: Node = mapPackedScene.instantiate()
		var tilemap: Node = map.get_node_or_null('TilemapRoot')
		if tilemap == null:
			printerr('Scene ', path, ' has no TilemapRoot node as a child of the root node!!')
		else:
			# test for tilemap layers with collision visibility force shown
			for child: Node in tilemap.get_children():
				if child is TileMapLayer:
					if child.collision_visibility_mode == 1: #DEBUG_VISIBILITY_MODE_FORCE_SHOW = 1
						if forceShownCollisionMaps.has(path):
							forceShownCollisionMaps[path].append(child.name)
						else:
							forceShownCollisionMaps[path] = [child.name]
						#printerr('Scene', path, ' / tilemap layer ', child.name, ' has force show collision visibility enabled')
			add_child(map)
			# check test tools
			var testTools: Array[Node] = get_tree().get_nodes_in_group('TestTool')
			var testToolNames: Array[String] = []
			for node: Node in testTools:
				testToolNames.append(node.name)
			if len(testToolNames) > 0:
				hasTestTools[path] = testToolNames
			# check spawners
			var spawners: Array[Node] = get_tree().get_nodes_in_group('EnemySpawner')
			var quietedWarningSpawnerNames: Array[String] = []
			for node: Node in spawners:
				var spawner: EnemySpawner = node as EnemySpawner
				if spawner.quietWarnings:
					quietedWarningSpawnerNames.append(node.name)
				if len(quietedWarningSpawnerNames) > 0:
					hasSpawnersQuietingWarnings[path] = quietedWarningSpawnerNames
			var interactables: Array[Node] = get_tree().get_nodes_in_group('Interactable')
			var quietedWarningGroundItemNames: Array[String] = []
			for node: Node in interactables:
				if node is GroundItem:
					var groundItem: GroundItem = node as GroundItem
					if groundItem.quietWarnings:
						quietedWarningGroundItemNames.append(node.name)
					if len(quietedWarningGroundItemNames) > 0:
						hasGroundItemsQuietingWarnings[path] = quietedWarningGroundItemNames
			# check ground items
			remove_child(map)
			map.queue_free()
	print()
	print('==================================')
	print('Results:')
	print('==================================')
	print('Maps with collision force shown:')
	for collisionShownMap: String in forceShownCollisionMaps.keys():
		var layers: Array[String] = forceShownCollisionMaps[collisionShownMap]
		for layer: String in layers:
			printerr('Map ', collisionShownMap, ' / TileMapLayer ', layer, ' has force show collision visibility enabled')
	print('----------------------------------')
	print('Maps with test tools still instantiated:')
	for testToolMap: String in hasTestTools.keys():
		var toolNames: Array[String] = hasTestTools[testToolMap]
		printerr('Map ', testToolMap, ' has tools: ', toolNames)
	print('----------------------------------')
	print('Maps with spawners quieting warnings:')
	for spawnerMap: String in hasSpawnersQuietingWarnings.keys():
		var spawnerNames: Array[String] = hasSpawnersQuietingWarnings[spawnerMap]
		printerr('Map ', spawnerMap, ' has spawners quieting warnings: ', spawnerNames)
	print('----------------------------------')
	print('Maps with ground items quieting warnings:')
	for groundItemMap: String in hasGroundItemsQuietingWarnings.keys():
		var groundItemNames: Array[String] = hasGroundItemsQuietingWarnings[groundItemMap]
		printerr('Map ', groundItemMap, ' has ground items quieting warnings: ', groundItemNames)
	print('----------------------------------')
	#'''


func get_overworld_map_paths(dirPath: String) -> Array[String]:
	#print('get maps at ', dirPath)
	var mapPaths: Array[String] = []
	var subdirs: PackedStringArray = DirAccess.get_directories_at(dirPath)
	for dir: String in subdirs:
		mapPaths.append_array(get_overworld_map_paths(dirPath + '/' + dir))
	
	var files: PackedStringArray = DirAccess.get_files_at(dirPath)
	for file: String in files:
		mapPaths.append(dirPath + '/' + file)
	
	return mapPaths
