extends CutsceneDialogue
class_name StoryReqsCutsceneDialogue

## alternative dialogues to use instead of this one; if none of the story requirements for any of the alternatives passes, then the base `CutsceneDialogue` properties on this object will be used instead
@export var storyReqsAlternatives: Array[CutsceneDialogueAlternative] = []

func _init(
	i_speaker = '',
	i_texts: Array[String] = [],
	i_textboxSfxs: Array[AudioStream] = [],
	i_alternatives: Array[CutsceneDialogueAlternative] = [],
) -> void:
	super(i_speaker, i_texts, i_textboxSfxs)
	storyReqsAlternatives = i_alternatives

func get_cutscene_dialogue() -> CutsceneDialogue:
	for alt: CutsceneDialogueAlternative in storyReqsAlternatives:
		if alt.is_valid():
			return alt
	return self # if none of the alternatives pass: the default dialogue is used
