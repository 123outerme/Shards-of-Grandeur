extends Resource
class_name WorldLocation

enum MapLocation {
	UNKNOWN = 0, ## Unknown location (not shown on map)
	GRANDSTONE = 10, ## Grandstone
	STANDSTILL = 20, ## Standstill
	HILLTOP_FOREST = 21, ## Hilltop Forest
	MUSHROOM_GROTTO = 22, ## Mushroom Grotto
	LEAVENPORT = 30, ## Leavenport
	SEA_LEG_SWAMP_EAST = 31, ## Sea Leg Swamp, east of Leavenport
	SEA_LEG_SWAMP_SOUTH = 32, ## Sea Leg Swamp, south of Leavenport
	NOMAD_CAMP = 40, ## Nomad Camp
	FORBIDDEN_DESERT_SOUTH = 41, ## Forbidden Desert, south of Nomad Camp
	FORBIDDEN_DESERT_EAST = 42, ## Forbidden Desert, east of Nomad Camp
}

@export var locationName: String = ''
@export var maps: Array[MapEntry] = []
@export var mapLocation: MapLocation = MapLocation.UNKNOWN

static func map_location_to_string(location: MapLocation) -> String:
	match location:
		MapLocation.UNKNOWN:
			return 'Unknown'
		MapLocation.GRANDSTONE:
			return 'Grandstone'
		MapLocation.STANDSTILL:
			return 'Standstill'
		MapLocation.HILLTOP_FOREST:
			return 'Hilltop Forest'
		MapLocation.LEAVENPORT:
			return 'Leavenport'
		MapLocation.MUSHROOM_GROTTO:
			return 'Mushroom Grotto'
		MapLocation.SEA_LEG_SWAMP_EAST:
			return 'Sea Leg Swamp'
		MapLocation.SEA_LEG_SWAMP_SOUTH:
			return 'Sea Leg Swamp'
		MapLocation.FORBIDDEN_DESERT_SOUTH:
			return 'Forbidden Desert'
		MapLocation.FORBIDDEN_DESERT_EAST:
			return 'Forbidden Desert'
		MapLocation.NOMAD_CAMP:
			return 'Nomad Camp'
	return 'Unknown'

func _init(i_locationName: String = '', i_maps: Array[MapEntry] = []):
	locationName = i_locationName
	maps = i_maps

func get_map_entry_for_location() -> MapEntry:
	for map in maps:
		if map.requirements == null or map.requirements.is_valid():
			return map
	return null
