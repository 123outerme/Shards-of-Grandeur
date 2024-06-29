extends WeightedThing
class_name WeightedDialogueEntry

@export var dialogueEntry: DialogueEntry = null

func _init(i_weight = 0.0, i_dialogueEntry = null):
	super(i_weight)
	dialogueEntry = i_dialogueEntry
