extends CutsceneDialogue
class_name CutsceneDialogueAlternative
## Useless as a sub-resource of a cutscene; this should only be the sub-resource of a StoryReqsCutsceneDialogue

## OR'd list of story requirements for this dialogue to be used
@export var storyRequirements: Array[StoryRequirements] = []

func _init(
	i_speaker: String = '',
	i_texts: Array[String] = [],
	i_textboxSfx: AudioStream = null,
	i_storyReqs: Array[StoryRequirements] = [],
):
	super(i_speaker, i_texts, i_textboxSfx)
	storyRequirements = i_storyReqs

func is_valid() -> bool:
	var isValid: bool = len(storyRequirements) == 0
	for req: StoryRequirements in storyRequirements:
		if req.is_valid():
			isValid = true
			break
	return isValid
