extends InteractableDialogue
class_name PickedUpItem

@export_category("PickedUpItem - Overworld data")
## the item that should be given when the player picks up the GroundItem interactable
@export var item: Item

## player usage only; for temporarily holding whether or not the item could be added to the player inventory, or if it's too full 
@export_storage var wasPickedUp: bool = false

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
