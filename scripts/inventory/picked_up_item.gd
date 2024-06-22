extends InteractableDialogue
class_name PickedUpItem

@export_category("PickedUpItem - Overworld data")
@export var item: Item

@export_category("PickedUpItem - Save Data: Do Not Modfiy")
@export var wasPickedUp: bool = false

func _init(
	i_speaker = '',
	i_dialogueEntry = null,
	i_savedItemIdx = 0,
	i_savedTextIdx = 0,
	i_item = null,
	i_wasPickedUp = false,
):
	super(i_speaker, i_dialogueEntry, i_savedItemIdx, i_savedTextIdx)
	item = i_item
	wasPickedUp = i_wasPickedUp
