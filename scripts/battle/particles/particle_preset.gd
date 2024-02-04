extends Resource
class_name ParticlePreset

@export var type: String = ''
@export var count: int = 0

func _init(
	i_type = '',
	i_count = 0,
):
	type = i_type
	count = i_count
