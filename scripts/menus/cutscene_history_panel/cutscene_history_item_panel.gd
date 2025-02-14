extends Panel
class_name CutsceneHistoryItemPanel

@export var cutsceneDialogue: CutsceneDialogue = null
@export var textIdx: int = -1
@export var isFirst: bool = true

const SPEAKER_SHOWN_HEIGHT: int = 193
const SPEAKER_HIDDEN_HEIGHT: int = 131

@onready var speakerSection: HBoxContainer = get_node('TextContainer/MarginContainer/VBoxContainer/SpeakerSection')
@onready var speakerSpriteControl: Control = get_node('TextContainer/MarginContainer/VBoxContainer/SpeakerSection/SpeakerSpriteControl')
@onready var speakerSprite: AnimatedSprite2D = get_node('TextContainer/MarginContainer/VBoxContainer/SpeakerSection/SpeakerSpriteControl/SpeakerSprite')
@onready var speakerText: RichTextLabel = get_node('TextContainer/MarginContainer/VBoxContainer/SpeakerSection/SpeakerText')

@onready var textboxText: RichTextLabel = get_node('TextContainer/MarginContainer/VBoxContainer/TextBoxText')

func load_cutscene_history_item_panel() -> void:
	if cutsceneDialogue == null or textIdx < 0 or textIdx > len(cutsceneDialogue.texts):
		return
	visible = true
	
	if isFirst:
		speakerSection.visible = true
		custom_minimum_size.y = SPEAKER_SHOWN_HEIGHT
		if (cutsceneDialogue.speakerSpriteFrames == null and cutsceneDialogue.speakerActorScenePath == '' and not cutsceneDialogue.speakerActorIsPlayer) \
				or cutsceneDialogue.speakerAnim == '':
			speakerSpriteControl.visible = false
		else:
			speakerSpriteControl.visible = true
			var spriteFrames: SpriteFrames = cutsceneDialogue.speakerSpriteFrames
			var spriteScale: int = cutsceneDialogue.speakerAnimScale
			if cutsceneDialogue.speakerActorScenePath != '' or cutsceneDialogue.speakerActorIsPlayer:
				var actorSpriteFrames: SpriteFrames = SceneLoader.cutscenePlayer.fetch_actor_sprite_frames(cutsceneDialogue.speakerActorScenePath, cutsceneDialogue.speakerActorIsPlayer)
				if actorSpriteFrames != null:
					spriteFrames = actorSpriteFrames
			if cutsceneDialogue.speakerActorIsPlayer:
				var playerSpriteObj: CombatantSprite = PlayerResources.playerInfo.combatant.get_sprite_obj()
				# use idle size since `maxSize` means sprite's canvas size
				var maxDimensionSize: float = max(playerSpriteObj.idleSize.x, playerSpriteObj.idleSize.y)
				# scale of 3x if [16x16, 16x16], 2x if (16x16, 32x32], 1x if bigger than that
				spriteScale = max(1, 4 - ceil(maxDimensionSize / 16.0))
			speakerSprite.sprite_frames = spriteFrames
			speakerSprite.offset = cutsceneDialogue.animSpeakerOffset
			speakerSprite.play(cutsceneDialogue.speakerAnim)
			speakerSprite.scale = Vector2.ONE * spriteScale
		speakerText.text = TextUtils.rich_text_substitute(cutsceneDialogue.speaker, Vector2i(32, 32)) + ':'
	else:
		speakerSection.visible = false
		custom_minimum_size.y = SPEAKER_HIDDEN_HEIGHT
	textboxText.text = TextUtils.rich_text_substitute(cutsceneDialogue.texts[textIdx], Vector2i(32, 32))

func _on_speaker_sprite_animation_finished() -> void:
	await get_tree().create_timer(2).timeout
	speakerSprite.play(cutsceneDialogue.speakerAnim)
