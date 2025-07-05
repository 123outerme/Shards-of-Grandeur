extends Resource
class_name NpcSpriteState

## the state ID string to identify the state by
@export var id: String = ''

## defines the priority by which this state will be auto-applied on NPC load or if more than one state would be auto-applied; ties are broken by natural String order of the IDs (case-insensitive)
@export var priority: int = 0

## The SpriteFrames resource to apply to the NPC on this state; null == default attached SpriteFrames
@export var spriteFrames: SpriteFrames = null

## Story requirements to automatically apply this State if `autoApplyState` is true
@export var storyRequirements: Array[StoryRequirements] = []

## If true, will check the `storyRequirements` and if valid, will automatically switch to this state
@export var autoApplyState: bool = false


## compare function for custom sort
static func compare(a: NpcSpriteState, b: NpcSpriteState) -> bool:
	if b.priority > a.priority:
		return false
	
	if a.priority == b.priority:
		if b.id.naturalnocasecmp_to(a.id) < 0:
			return false
	
	return true

func _init(
	i_id: String = '',
	i_priority: int = 0,
	i_spriteFrames: SpriteFrames = null,
	i_storyRequirements: Array[StoryRequirements] = [],
	i_autoApplyState: bool = false,
):
	id = i_id
	priority = i_priority
	spriteFrames = i_spriteFrames
	storyRequirements = i_storyRequirements
	autoApplyState = i_autoApplyState

func is_valid() -> bool:
	return StoryRequirements.list_is_valid(storyRequirements)
