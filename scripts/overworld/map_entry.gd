extends Resource
class_name MapEntry

## the map path for this map
@export var path: String = ''

## story requirements for this `MapEntry` to be used for loading. One `MapEntry` in a `WorldLocation` MUST have `storyRequirements = null`
@export var requirements: StoryRequirements = null

## the track to loop in the overworld
@export var overworldTheme: AudioStream = null

## the name of the battle map scene to load when encountering on this map
@export var battleMapName: String = 'forest_battle_map'

## an array of possible battle tracks to play when encountering on this map
@export var battleMusic: Array[AudioStream] = []

## if true, if this is the last location the player visited before losing a battle, they will respawn at this map
@export var isRecoverLocation: bool = false

## if `isRecoverLocation` is true, the place where the player should spawn after recovering
@export var recoverPosition: Vector2 = Vector2()

static func get_battle_map_scene_path(mapName: String) -> String:
	return 'res://prefabs/battle/battle_maps/' + mapName + '.tscn'

func _init(
	i_path = '',
	i_requirements = null,
	i_overworldTheme = null,
	i_battleMapName = '',
	i_battleMusic: Array[AudioStream] = [],
	i_isRecover = false,
	i_recoverPos = Vector2(),
):
	path = i_path
	requirements = i_requirements
	overworldTheme = i_overworldTheme
	battleMapName = i_battleMapName
	battleMusic = i_battleMusic
	isRecoverLocation = i_isRecover
	recoverPosition = i_recoverPos

func get_map_path() -> String:
	return 'res://prefabs/maps/' + path + '.tscn'

func get_battle_map_path() -> String:
	return MapEntry.get_battle_map_scene_path(battleMapName)
