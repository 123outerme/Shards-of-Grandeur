extends CutsceneDialogue
class_name CutsceneDialogueAlternative
## Useless as a sub-resource of a cutscene; this should only be the sub-resource of a StoryReqsCutsceneDialogue

## OR'd list of story requirements for this dialogue to be used
@export var storyRequirements: Array[StoryRequirements] = []

func _init(
	i_speaker: String = '',
	i_texts: Array[String] = [],
	i_textboxSfxs: Array[AudioStream] = [],
	i_storyReqs: Array[StoryRequirements] = [],
):
	super(i_speaker, i_texts, i_textboxSfxs)
	storyRequirements = i_storyReqs

func is_valid() -> bool:
	return StoryRequirements.list_is_valid(storyRequirements)
