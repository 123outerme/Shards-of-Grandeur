extends Resource
class_name InteractableDialogue

@export var speaker: String = ''
@export var dialogueEntry: DialogueEntry = null

@export_category("InteractableDialogue - Save Data: Do Not Modify")
@export_storage var savedItemIdx: int = 0
@export_storage var savedTextIdx: int = 0

func _init(
	i_speaker = '',
	i_dialogueEntry = null,
	i_savedItemIdx = 0,
	i_savedTextIdx = 0,
):
	speaker = i_speaker
	dialogueEntry = i_dialogueEntry
	savedItemIdx = i_savedItemIdx
	savedTextIdx = i_savedTextIdx

func can_use_dialogue():
	return dialogueEntry != null and dialogueEntry.can_use_dialogue()
