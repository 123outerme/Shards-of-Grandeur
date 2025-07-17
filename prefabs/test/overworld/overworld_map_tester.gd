extends Node

func _ready() -> void:
	var paths: Array[String] = get_overworld_map_paths('res://prefabs/maps')
	#print(paths)
	#'''
	var forceShownCollisionMaps: Dictionary[String, Array] = {}
	
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
