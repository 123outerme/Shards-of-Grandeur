extends Resource
class_name CodexEntry

@export var id: String = ''
@export var title: String = ''
@export var storyRequirements: Array[StoryRequirements] = []
@export_multiline var description: String = ''
@export var image: Texture2D = null

## order that this entry's button appears (0 = top of the list, increasing moves towards the bottom)
@export var sortOrder: int = 0

## for resolving ID conflicts, higher priority number wins
@export var priority: int = 0

static func _sort_entries(a: CodexEntry, b: CodexEntry) -> bool:
	if a.sortOrder < b.sortOrder:
		return true
	elif a.sortOrder > b.sortOrder:
		return false
	return a.resource_path.naturalnocasecmp_to(b.resource_path) < 0

func _init(
	i_id = '',
	i_title = '',
	i_storyRequirements: Array[StoryRequirements] = [],
	i_description = '',
	i_image: Texture2D = null,
	i_sortOrder = 0,
	i_priority = 0,
):
	id = i_id
	title = i_title
	storyRequirements = i_storyRequirements
	description = i_description
	image = i_image
	sortOrder = i_sortOrder
	priority = i_priority

func is_valid():
	return StoryRequirements.list_is_valid(storyRequirements)
