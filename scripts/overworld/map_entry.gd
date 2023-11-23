extends Resource
class_name MapEntry

@export var path: String = ''
@export var requirements: StoryRequirements = null

func _init(
	i_path = '',
	i_requirements = null
):
	path = i_path
	requirements = i_requirements

func get_map_path() -> String:
	return 'res://prefabs/maps/' + path + '.tscn'
