extends Resource
class_name CutsceneDialogue

@export var speaker: String = ''
@export_multiline var texts: Array[String] = []
@export var textboxSfx: AudioStream = null

func _init(
	i_speaker = '',
	i_texts: Array[String] = [],
	i_textboxSfx = null,
):
	speaker = i_speaker
	texts = i_texts
	textboxSfx = i_textboxSfx

## gets the final cutscene dialogue to be used in this instance
func get_cutscene_dialogue() -> CutsceneDialogue:
	return self # overridden in subclasses to return the proper dialogue for the occasion!
