extends Resource
class_name DialogueItem

@export_multiline var lines: Array[String]

## for NPCs using this dialogue item, the NPC will play this animation until all this item's text is advanced. For Interactables, will tell the interactable to play this animation once this item's text is shown.
@export var animation: String = ''

@export var choices: Array[DialogueChoice] = []

func _init(
	i_lines: Array[String] = [],
	i_animation = '',
	i_choices: Array[DialogueChoice] = [],
):
	lines = i_lines
	animation = i_animation
	choices = i_choices
