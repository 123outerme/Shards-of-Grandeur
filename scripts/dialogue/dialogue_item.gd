extends Resource
class_name DialogueItem

@export_multiline var lines: Array[String]

## For the line of the matching array index, prevents the textbox from being advanced past that line for that many seconds.
@export var minShowSecs: Array[float] = []

## for NPCs using this dialogue item, the actor will play this animation until all this item's text is advanced. For Interactables, will tell the interactable to play this animation once this item's text is shown.
@export var animation: String = ''

## For this dialogue item, this speaker (if defined) will be used instead of whichever was intially shown. After this line, either the next line's override is used, or the original speaker will be restored.
@export var speakerOverride: String = ''

## If defined, will have an actor that is not the originating actor play this animation. `animateActorTreePath` and `animateActorIsPlayer` control which actor plays this animation.
@export var actorAnimation: String = ''

## For this dialogue, this "actor" (if defined) will have the `animation` played.
@export var animateActorTreePath: String = ''

## If true, the player will play the `actorAnimation`. Overrides the `animateActorTreePath` completely.
@export var animateActorIsPlayer: bool = false

@export var choices: Array[DialogueChoice] = []

func _init(
	i_lines: Array[String] = [],
	i_minShowSecs: Array[float] = [],
	i_animation = '',
	i_speakerOverride = '',
	i_actorAnimation = '',
	i_animateActorTreePath = '',
	i_animateActorIsPlayer = false,
	i_choices: Array[DialogueChoice] = [],
):
	lines = i_lines
	minShowSecs = i_minShowSecs
	animation = i_animation
	speakerOverride = i_speakerOverride
	actorAnimation = i_actorAnimation
	animateActorTreePath = i_animateActorTreePath
	animateActorIsPlayer = i_animateActorIsPlayer
	choices = i_choices


func get_lines() -> Array[String]:
	return lines

func get_min_show_secs(idx: int) -> float:
	if idx >= len(minShowSecs) or idx < 0:
		return 0
	return minShowSecs[idx]
	
