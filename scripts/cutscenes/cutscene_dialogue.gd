extends Resource
class_name CutsceneDialogue

@export var speaker: String = ''
@export_multiline var texts: Array[String] = []

func _init(
	i_speaker = '',
	i_texts: Array[String] = [],
):
	speaker = i_speaker
	texts = i_texts
