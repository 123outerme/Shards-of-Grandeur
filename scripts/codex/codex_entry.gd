extends Resource
class_name CodexEntry

@export var id: String = ''
@export var title: String = ''
@export var storyRequirements: Array[StoryRequirements] = []
@export_multiline var description: String = ''
@export var image: Texture2D = null
@export var sortOrder: int = 0

static func _sort_entries(a: CodexEntry, b: CodexEntry) -> bool:
	if a.sortOrder < b.sortOrder:
		return true
	return false

func _init(
	i_id = '',
	i_title = '',
	i_storyRequirements: Array[StoryRequirements] = [],
	i_description = '',
	i_image: Texture2D = null,
	i_sortOrder = 0
):
	id = i_id
	title = i_title
	storyRequirements = i_storyRequirements
	description = i_description
	image = i_image
	sortOrder = i_sortOrder

func is_valid():
	var valid: bool = false
	
	for requirements in storyRequirements:
		valid = valid or requirements.is_valid()
	
	return valid or len(storyRequirements) == 0
