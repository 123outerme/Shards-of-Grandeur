extends Resource
class_name MapEntry

@export var path: String = ''
@export var requirements: StoryRequirements = null
@export var isRecoverLocation: bool = false
@export var recoverPosition: Vector2 = Vector2()

func _init(
	i_path = '',
	i_requirements = null,
	i_isRecover = false,
	i_recoverPos = Vector2(),
):
	path = i_path
	requirements = i_requirements
	isRecoverLocation = i_isRecover
	recoverPosition = i_recoverPos

func get_map_path() -> String:
	return 'res://prefabs/maps/' + path + '.tscn'
