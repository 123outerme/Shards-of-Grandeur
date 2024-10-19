extends Resource
class_name WorldLocation

enum MapLocation {
	UNKNOWN = 0, ## Unknown location (not shown on map)
	GRANDSTONE = 1, ## Grandstone
	STANDSTILL = 2, ## Standstill
	HILLTOP_FOREST = 3, ## Hilltop Forest
	LEAVENPORT = 4, ## Leavenport
	MUSHROOM_GROTTO = 5, ## Mushroom Grotto
	SEA_LEG_SWAMP_EAST = 6, ## Sea Leg Swamp, east of Leavenport
	SEA_LEG_SWAMP_SOUTH = 7, ## Sea Leg Swamp, south of Leavenport
	FORBIDDEN_DESERT_SOUTH = 8, ## Forbidden Desert, south of Nomad Camp
	NOMAD_CAMP = 9, ## Nomad Camp
	FORBIDDEN_DESERT_EAST = 10, ## Forbidden Desert, east of Nomad Camp
	MAX_LOCATIONS = 11, ## Do not select as a location; for iterating through all locations. Update this every time the MapLocations enum becomes larger
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
