extends Node2D
class_name TextBox

@export var textScrollSfx: AudioStream = null
@export var advanceDialogueSfx: Array[AudioStream] = []
@export var buttonRow: HBoxContainer

var dialogueItem: DialogueItem = null
var lastDialogueItem: bool = false
var lastChoiceFocused: Button = null
var choicesDialogueItemIdxs: Array[int] = []
# the item at index `idx` will be the dialogueItem corresponding to the button

var chars_per_sec: float = 40
var text_visible_chars_partial: float = 0

var speaker_chars_per_sec: float = 40
var speaker_visible_chars_partial: float = 0

static var buttonScene: PackedScene = preload('res://prefabs/ui/sfx_button.tscn')

@onready var TextBoxText: RichTextLabel = get_node("Panel/TextContainer/MarginContainer/VBoxContainer/TextBoxText")
@onready var SpeakerText: RichTextLabel = get_node("Panel/TextContainer/MarginContainer/VBoxContainer/SpeakerText")
@onready var ReadySprite: Sprite2D = get_node("ReadySprite")
@onready var buttonContainer: HBoxContainer = get_node('Panel/ScrollBetterFollow/HBoxContainer')

# Called when the node enters the scene tree for the first time.
func _ready():
	get_viewport().gui_focus_changed.connect(_viewport_focus_changed)

func _unhandled_input(event):
	if visible and event.is_action_pressed("game_decline") and is_textbox_complete() and PlayerFinder.player.makingChoice:
		get_viewport().set_input_as_handled()
		select_decline_choice()

func _exit_tree():
	SceneLoader.audioHandler.stop_sfx(textScrollSfx)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if SpeakerText.visible_characters < len(SpeakerText.text):
		speaker_visible_chars_partial += speaker_chars_per_sec * delta
		SpeakerText.visible_characters = min(round(speaker_visible_chars_partial), len(SpeakerText.text))
	else:
		if TextBoxText.visible_characters < len(TextBoxText.text):
			text_visible_chars_partial += chars_per_sec * delta
			TextBoxText.visible_characters = min(round(text_visible_chars_partial), len(TextBoxText.text))
		else:
			add_choices()
			ReadySprite.visible = true
			SceneLoader.audioHandler.stop_sfx(textScrollSfx)

func set_textbox_text(text: String, speaker: String, lastItem: bool = true):
	advance_textbox(text, lastItem)
	var newSpeaker: bool = false
	if speaker == '':
		newSpeaker = SpeakerText.text != ''
		SpeakerText.text = ''
	elif SpeakerText.text != TextUtils.substitute_playername(speaker) + ":":
		SpeakerText.text = TextUtils.substitute_playername(speaker) + ":"
		newSpeaker = true
	delete_choices()
	visible = true
	ReadySprite.visible = false
	lastDialogueItem = lastItem
	if newSpeaker:
		SpeakerText.visible_characters = 0
		speaker_visible_chars_partial = 0
	SceneLoader.audioHandler.play_sfx(textScrollSfx, -1)
	
func advance_textbox(text: String, lastItem: bool = true):
	TextBoxText.text = TextUtils.substitute_playername(text)
	TextBoxText.visible_characters = 0
	text_visible_chars_partial = 0
	ReadySprite.visible = false
	SceneLoader.audioHandler.play_sfx(textScrollSfx, -1)
	lastDialogueItem = lastItem
	delete_choices()

func is_textbox_complete() -> bool:
	return ReadySprite.visible or (len(TextBoxText.text) == 0 and len(SpeakerText.text) == 0)

func add_choices():
	if dialogueItem == null or PlayerFinder.player.makingChoice \
			or TextBoxText.text != TextUtils.substitute_playername(dialogueItem.lines[len(dialogueItem.lines) - 1]):
		return
	
	delete_choices()
	var buttonIdx: int = 0
	for idx in range(len(dialogueItem.choices)):
		#if buttonIdx >= 5:
		#	continue
		
		#get_node('Panel/HBoxContainer/Button' + String.num_int64(buttonIdx + 1))
		
		if dialogueItem.choices[idx].is_valid() \
				and not (dialogueItem.choices[idx].leadsTo != null and not dialogueItem.choices[idx].leadsTo.can_use_dialogue()):
			var choice = dialogueItem.choices[idx]
			if choice.turnsInQuest != '':
				var questName = choice.turnsInQuest.split('#')[0]
				var stepName = choice.turnsInQuest.split('#')[1]
				var questTracker: QuestTracker = PlayerResources.questInventory.get_quest_tracker_by_name(questName)
				if questTracker != null:
					if questTracker.get_step_status(questTracker.get_step_by_name(stepName)) != QuestTracker.Status.READY_TO_TURN_IN_STEP:
						continue
				else:
					continue
			choicesDialogueItemIdxs.append(idx)
			var button: Button = buttonScene.instantiate()
			buttonContainer.add_child(button)
			button.text = TextUtils.substitute_playername(choice.choiceBtn)
			button.custom_minimum_size = choice.buttonDims
			button.visible = true
			button.pressed.connect(_select_choice.bind(buttonIdx))
			if buttonIdx == 0:
				button.call_deferred('grab_focus')
			buttonIdx += 1
		else:
			if buttonIdx == 0:
				refocus_choice(null) # focus the first button that is being shown
		
	PlayerFinder.player.makingChoice = buttonIdx > 0

func delete_choices():
	PlayerFinder.player.makingChoice = false
	for node in buttonContainer.get_children():
		node.queue_free()
		#var button: Button = get_node('Panel/HBoxContainer/Button' + String.num_int64(idx + 1))
		#button.visible = false
	choicesDialogueItemIdxs = []
	lastChoiceFocused = null

func refocus_choice(choice: DialogueChoice = null):
	if lastChoiceFocused:
		lastChoiceFocused.grab_focus()
	else:
		var buttons: Array[Node] = buttonContainer.get_children()
		for idx in range(len(buttons)):
			#var button: Button = get_node('Panel/HBoxContainer/Button' + String.num_int64(idx + 1))
			var button: Button = buttons[idx]
			if button != null and button.visible and (choice == null or TextUtils.substitute_playername(choice.choiceBtn) == button.text):
				button.grab_focus()
				return

func hide_textbox():
	visible = false
	dialogueItem = null
	lastDialogueItem = false
	lastChoiceFocused = null
	SpeakerText.text = ''
	TextBoxText.text = ''
	SpeakerText.visible_characters = 0
	speaker_visible_chars_partial = 0
	TextBoxText.visible_characters = 0
	text_visible_chars_partial = 0
	ReadySprite.visible = false
	delete_choices()

func show_text_instant():
	SpeakerText.visible_characters = len(SpeakerText.text)
	TextBoxText.visible_characters = len(TextBoxText.text)
	SceneLoader.audioHandler.stop_sfx(textScrollSfx)
	var advanceIdx = 0
	if lastDialogueItem:
		advanceIdx = 1
	SceneLoader.audioHandler.play_sfx(advanceDialogueSfx[advanceIdx])
	add_choices()

func select_decline_choice():
	if not PlayerFinder.player.makingChoice or dialogueItem == null:
		return
	var buttons: Array[Node] = buttonContainer.get_children()
	for idx in range(len(buttons)):
		var button: Button = buttons[idx]
		if dialogueItem.choices[choicesDialogueItemIdxs[idx]].isDeclineChoice:
			_select_choice(idx)
			return

func _viewport_focus_changed(control):
	var buttons: Array[Node] = buttonContainer.get_children()
	for idx in range(len(buttons)):
		var button: Button = buttons[idx]
		#var button: Button = get_node('Panel/HBoxContainer/Button' + String.num_int64(idx + 1))
		if button == control:
			lastChoiceFocused = button
	
func _select_choice(idx: int):
	#print(dialogueItem.choices[idx].leadsTo.entryId, ' what is going on')
	PlayerFinder.player.select_choice(dialogueItem.choices[choicesDialogueItemIdxs[idx]])
	lastChoiceFocused = null
