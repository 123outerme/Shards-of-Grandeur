extends DialogueItem
class_name StoryReqsDialogueItem

@export var alternativeDialogueItems: Array[DialogueItem] = []
@export var alternativeStoryReqs: Array[StoryRequirements] = []

func _init(
	i_lines: Array[String] = [],
	i_minShowSecs: Array[float] = [],
	i_animation = '',
	i_speakerOverride = '',
	i_actorAnimation = '',
	i_animateActorTreePath = '',
	i_animateActorIsPlayer = false,
	i_choices: Array[DialogueChoice] = [],
	i_alternativeDialogueItems: Array[DialogueItem] = [],
	i_altStoryReqs: Array[StoryRequirements] = [],
):
	super(i_lines, i_minShowSecs, i_animation, i_speakerOverride, i_actorAnimation, i_animateActorTreePath, i_animateActorIsPlayer, i_choices)
	alternativeDialogueItems = i_alternativeDialogueItems
	alternativeStoryReqs = i_altStoryReqs

func get_lines() -> Array[String]:
	if len(alternativeDialogueItems) != len(alternativeStoryReqs):
		push_warning('StoryReqsDialogueItem get_lines() WARNING: number of alt dialogue items does not equal number of alt story requirements for resource ', resource_path)
	
	for idx: int in range(len(alternativeDialogueItems)):
		var storyReqs: StoryRequirements = null
		if idx < len(alternativeStoryReqs):
			storyReqs = alternativeStoryReqs[idx]
		if storyReqs == null or storyReqs.is_valid():
			return alternativeDialogueItems[idx].get_lines()
	
	return super.get_lines()

func get_choices() -> Array[DialogueChoice]:
	if len(alternativeDialogueItems) != len(alternativeStoryReqs):
		push_warning('StoryReqsDialogueItem get_choices() WARNING: number of alt dialogue items does not equal number of alt story requirements for resource ', resource_path)
	
	for idx: int in range(len(alternativeDialogueItems)):
		var storyReqs: StoryRequirements = null
		if idx < len(alternativeStoryReqs):
			storyReqs = alternativeStoryReqs[idx]
		if storyReqs == null or storyReqs.is_valid():
			return alternativeDialogueItems[idx].get_choices()
	
	return super.get_choices()

func get_min_show_secs(idx: int) -> float:
	if len(alternativeDialogueItems) != len(alternativeStoryReqs):
		push_warning('StoryReqsDialogueItem get_min_show_secs() WARNING: number of alt dialogue items does not equal number of alt story requirements for resource ', resource_path)
	
	for itemIdx: int in range(len(alternativeDialogueItems)):
		var storyReqs: StoryRequirements = null
		if idx < len(alternativeStoryReqs):
			storyReqs = alternativeStoryReqs[itemIdx]
		if storyReqs == null or storyReqs.is_valid():
			return alternativeDialogueItems[itemIdx].get_min_show_secs(idx)
	
	return super.get_min_show_secs(idx)
