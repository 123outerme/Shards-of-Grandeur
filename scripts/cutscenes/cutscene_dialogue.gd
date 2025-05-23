@tool
extends Resource
class_name CutsceneDialogue

## the speaker to indicate having said the dialogue
@export var speaker: String = ''

## dialogue to show
@export_multiline var texts: Array[String] = []

## SFX to play when the textbox opens
@export var textboxSfxs: Array[AudioStream] = []

## for display in cutscene dialogue history, next to speaker name
@export var speakerSpriteFrames: SpriteFrames = null

## if an actor in the world is used for this dialogue, will attempt to fetch that actor's SpriteFrames (fall-back is `speakerSpriteFrames`)
@export var speakerActorScenePath: String = ''

## If the player is used for this dialogue, will attempt to fetch the player's SpriteFrames
@export var speakerActorIsPlayer: bool = false

## the animation the speaker sprite should be playing
@export var speakerAnim: String = 'talk'

## the integer scaling to apply to the speaker sprite frames. Allocated speaker size in the UI is 48x48; don't go bigger!
@export_range(1, 10, 1, 'or_greater') var speakerAnimScale: int = 3

@export var animSpeakerOffset: Vector2 = Vector2.ZERO

func _init(
	i_speaker = '',
	i_texts: Array[String] = [],
	i_textboxSfxs: Array[AudioStream] = [],
	i_speakerSprite: SpriteFrames = null,
	i_speakerPath: String = '',
	i_speakerActorIsPlayer: bool = false,
	i_speakerAnim: String = 'talk',
	i_speakerScale: int = 3,
	i_speakerOffset: Vector2 = Vector2.ZERO,
):
	speaker = i_speaker
	texts = i_texts
	textboxSfxs = i_textboxSfxs
	speakerSpriteFrames = i_speakerSprite
	speakerActorScenePath = i_speakerPath
	speakerActorIsPlayer = i_speakerActorIsPlayer
	speakerAnim = i_speakerAnim
	speakerAnimScale = i_speakerScale
	animSpeakerOffset = i_speakerOffset

## gets the final cutscene dialogue to be used in this instance
func get_cutscene_dialogue() -> CutsceneDialogue:
	return self # overridden in subclasses to return the proper dialogue for the occasion!
