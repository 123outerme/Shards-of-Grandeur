extends Resource
class_name WorldLocation

@export var maps: Array[MapEntry] = []

func _init(i_maps: Array[MapEntry] = []):
	maps = i_maps

func get_map_entry_for_location() -> MapEntry:
	for map in maps:
		if map.requirements == null or map.requirements.is_valid():
			return map
	return null
