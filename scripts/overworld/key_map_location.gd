extends Resource
class_name KeyMapLocation

## ID for this key location (can have conflicts; settled by `priority`)
@export var id: String

## Name of the key location
@export var name: String

## MapLocation where this key location can be found
@export var locations: Array[WorldLocation.MapLocation] = []

## Story Requirements to show this key location
@export var storyRequirements: Array[StoryRequirements] = []

## Priority for de-conflicting key locations with the same `id`. Greater number beats smaller number
@export var priority: int = 0

## Sort order for lists of key locations. If >= 0, greater number comes after smaller number. Otherwise auto-sorted, where all auto-sorted comes after all specified sort orders
@export var sortOrder: int = -1

static func _sort(a: KeyMapLocation, b: KeyMapLocation) -> bool:
	if a.sortOrder < 0:
		if b.sortOrder < 0:
			return true
		else:
			return false
	if b.sortOrder < 0:
		return true
	
	if a.sortOrder > b.sortOrder:
		return false
	return true

func _init(
	i_id: String = '',
	i_name: String = '',
	i_locations: Array[WorldLocation.MapLocation] = [],
	i_storyRequirements: Array[StoryRequirements] = [],
	i_priority: int = 0,
	i_sortOrder: int = -1
) -> void:
	id = i_id
	name = i_name
	locations = i_locations
	storyRequirements = i_storyRequirements
	priority = i_priority

func is_valid() -> bool:
	return StoryRequirements.list_is_valid(storyRequirements)
