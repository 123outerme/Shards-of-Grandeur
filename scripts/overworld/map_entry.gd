extends Resource
class_name MapEntry

@export var path: String = ''
@export var requirements: StoryRequirements = null
@export var overworldTheme: AudioStream = null
@export var battleMapName: String = 'forest_battle_map'
@export var battleMusic: Array[AudioStream] = []
@export var isRecoverLocation: bool = false
@export var recoverPosition: Vector2 = Vector2()

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
	return 'res://prefabs/battle/battle_maps/' + battleMapName + '.tscn'
