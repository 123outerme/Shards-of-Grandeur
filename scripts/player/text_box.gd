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

var firstChoiceButton: Button = null
var lastChoiceButton: Button = null

var chars_per_sec: float = 40
var text_visible_chars_partial: float = 0

var speaker_chars_per_sec: float = 40
var speaker_visible_chars_partial: float = 0

static var buttonScene: PackedScene = preload('res://prefabs/ui/sfx_button.tscn')

@onready var TextBoxText: RichTextLabel = get_node("Panel/TextContainer/MarginContainer/VBoxContainer/TextBoxText")
@onready var SpeakerText: RichTextLabel = get_node("Panel/TextContainer/MarginContainer/VBoxContainer/SpeakerText")
@onready var ReadySprite: Sprite2D = get_node("Panel/ReadySprite")
@onready var buttonContainer: HBoxContainer = get_node('Panel/ScrollBetterFollow/HBoxContainer')
@onready var boxContainerScroller: BoxContainerScroller = get_node('Panel/BoxContainerScroller')

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
	elif SpeakerText.text != TextUtils.rich_text_substitute(speaker, Vector2i(32, 32)) + ":":
		SpeakerText.text = TextUtils.rich_text_substitute(speaker, Vector2i(32, 32)) + ":"
		newSpeaker = true
	delete_choices()
	visible = true
	PlayerFinder.player.overworldTouchControls.set_in_dialogue(true)
	ReadySprite.visible = false
	lastDialogueItem = lastItem
	if newSpeaker:
		SpeakerText.visible_characters = 0
		speaker_visible_chars_partial = 0
	SceneLoader.audioHandler.play_sfx(textScrollSfx, -1)

func advance_textbox(text: String, lastItem: bool = true, overrideSpeaker: String = ''):
	TextBoxText.text = TextUtils.rich_text_substitute(text, Vector2i(32, 32))
	TextBoxText.visible_characters = 0
	text_visible_chars_partial = 0
	if overrideSpeaker != '' and SpeakerText.text != TextUtils.rich_text_substitute(overrideSpeaker, Vector2i(32, 32)) + ":":
		SpeakerText.text = TextUtils.rich_text_substitute(overrideSpeaker, Vector2i(32, 32)) + ":"
		SpeakerText.visible_characters = 0
		speaker_visible_chars_partial = 0
	ReadySprite.visible = false
	lastDialogueItem = lastItem
	delete_choices()
	SceneLoader.audioHandler.play_sfx(textScrollSfx, -1)

func is_textbox_complete() -> bool:
	return ReadySprite.visible or (len(TextBoxText.text) == 0 and len(SpeakerText.text) == 0)

func add_choices():
	if dialogueItem == null:
		return
	var dialogueLines: Array[String] = dialogueItem.get_lines()
	if PlayerFinder.player.makingChoice \
			or TextBoxText.text != TextUtils.substitute_playername(dialogueLines[len(dialogueLines) - 1]):
		return
	
	delete_choices()
	var buttonIdx: int = 0
	var maxBtnHeight: float = 40
	for idx in range(len(dialogueItem.choices)):
		var isValid: bool = dialogueItem.choices[idx].is_valid()
		if dialogueItem.choices[idx].leadsTo != null:
			isValid = isValid and dialogueItem.choices[idx].leadsTo.can_use_dialogue()
		
		if len(dialogueItem.choices[idx].randomDialogues) > 0:
			# if at least one random option is valid, this can be selected
			var aDialogueOptionIsValid: bool = false
			for randomDialogue: WeightedDialogueEntry in dialogueItem.choices[idx].randomDialogues:
				aDialogueOptionIsValid = aDialogueOptionIsValid or randomDialogue.dialogueEntry.can_use_dialogue()
			isValid = isValid and aDialogueOptionIsValid
		
		# if a puzzle dialogue choice: check puzzle dialogue options for option validity
		if dialogueItem.choices[idx] is PuzzleDialogueChoice:
			var puzzleChoice: PuzzleDialogueChoice = dialogueItem.choices[idx] as PuzzleDialogueChoice
			# if a state puzzle, check state puzzle related options for validity
			if puzzleChoice.puzzle != null and puzzleChoice.puzzle is StatePuzzle:
				var statePuzzle: StatePuzzle = puzzleChoice.puzzle as StatePuzzle
				var currentStates: Array[String] = PlayerResources.playerInfo.get_puzzle_states(statePuzzle.id)
				# if the state is supposed to transition, this option is invalid if the transition cannot occur
				if puzzleChoice.setsState != '' and \
						puzzleChoice.puzzleStateIndex >= 0 and \
						puzzleChoice.puzzleStateIndex < len(currentStates):
					isValid = isValid and \
						statePuzzle.can_state_transition(puzzleChoice.setsState, currentStates[puzzleChoice.puzzleStateIndex], puzzleChoice.puzzleStateIndex)
		
		# choice is valid if it and the dialogue options it can lead to have valid StoryRequirements
		
		if isValid:
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
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			if choice.buttonDims.y > maxBtnHeight:
				maxBtnHeight = choice.buttonDims.y
			button.visible = true
			button.pressed.connect(_select_choice.bind(buttonIdx))
			if buttonIdx == 0:
				button.call_deferred('grab_focus')
			if firstChoiceButton == null:
				firstChoiceButton = button
				boxContainerScroller.bailoutFocusControl = button
				# left-scroll button's right neighbor set to the first button (if any) in the visibility changed signal callback below
			if lastChoiceButton != null:
				button.focus_neighbor_left = button.get_path_to(lastChoiceButton)
				lastChoiceButton.focus_neighbor_right = lastChoiceButton.get_path_to(button)
			lastChoiceButton = button
			buttonIdx += 1
		else:
			if buttonIdx == 0:
				refocus_choice(null) # focus the first button that is being shown
	# right-scroll button's left neighbor set to the last button (if any) in the visibility changed signal callback below
	# focus loops back around
	boxContainerScroller.connect_scroll_right_right_neighbor(boxContainerScroller.scrollLeftBtn)
	boxContainerScroller.connect_scroll_left_left_neighbor(boxContainerScroller.scrollRightBtn)
	boxContainerScroller.visible = false # set to not visible by default; if it needs to, it will update its own visibility the next process frame, then call the visibility changed signal callback below
	
	buttonContainer.custom_minimum_size.y = max(48, maxBtnHeight + 8)
	
	PlayerFinder.player.makingChoice = buttonIdx > 0
	

func delete_choices():
	boxContainerScroller.bailoutFocusControl = null
	PlayerFinder.player.makingChoice = false
	for node in buttonContainer.get_children():
		node.queue_free()
		#var button: Button = get_node('Panel/HBoxContainer/Button' + String.num_int64(idx + 1))
		#button.visible = false
	choicesDialogueItemIdxs = []
	lastChoiceFocused = null
	firstChoiceButton = null
	lastChoiceButton = null

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
	PlayerFinder.player.overworldTouchControls.set_in_dialogue(false)

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

func _on_box_container_scroller_visibility_changed() -> void:
	if boxContainerScroller == null: # prevent errors if this is triggered before _ready()
		return
	
	if boxContainerScroller.visible:
		if firstChoiceButton != null and lastChoiceButton != null:
			boxContainerScroller.connect_scroll_left_right_neighbor(firstChoiceButton)
			boxContainerScroller.connect_scroll_right_left_neighbor(lastChoiceButton)
	else:
		if firstChoiceButton != null and lastChoiceButton != null:
			firstChoiceButton.focus_neighbor_left = '.'
			lastChoiceButton.focus_neighbor_right = '.'
