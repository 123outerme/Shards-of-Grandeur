extends Node2D
class_name TextBox

@export var buttonRow: HBoxContainer

var dialogueItem: DialogueItem = null

var chars_per_sec: float = 40
var text_visible_chars_partial: float = 0

var speaker_chars_per_sec: float = 40
var speaker_visible_chars_partial: float = 0

@onready var TextBoxText: RichTextLabel = get_node("Panel/TextContainer/MarginContainer/VBoxContainer/TextBoxText")
@onready var SpeakerText: RichTextLabel = get_node("Panel/TextContainer/MarginContainer/VBoxContainer/SpeakerText")
@onready var ReadySprite: Sprite2D = get_node("ReadySprite")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

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

func set_textbox_text(text: String, speaker: String):
	advance_textbox(TextUtils.substitute_playername(text))
	SpeakerText.text = TextUtils.substitute_playername(speaker) + ":"
	visible = true
	SpeakerText.visible_characters = 0
	speaker_visible_chars_partial = 0
	
func advance_textbox(text: String):
	TextBoxText.text = text
	TextBoxText.visible_characters = 0
	text_visible_chars_partial = 0
	ReadySprite.visible = false

func is_textbox_complete() -> bool:
	return TextBoxText.visible_ratio == 1.0 or len(TextBoxText.text) == 0

func add_choices():
	if dialogueItem == null or PlayerFinder.player.makingChoice:
		return
	
	for idx in range(5):
		var button: Button = get_node('Panel/HBoxContainer/Button' + String.num_int64(idx + 1))
		if idx < len(dialogueItem.choices) and not (dialogueItem.choices[idx].leadsTo != null and not dialogueItem.choices[idx].leadsTo.can_use_dialogue()):
			var choice = dialogueItem.choices[idx]
			button.text = choice.choiceBtn
			button.custom_minimum_size = choice.buttonDims
			button.visible = true
			if idx == 0:
				button.call_deferred('grab_focus')
		else:
			button.visible = false
		
	PlayerFinder.player.makingChoice = len(dialogueItem.choices) > 0

func delete_choices():
	PlayerFinder.player.makingChoice = false
	for idx in range(5):
		var button: Button = get_node('Panel/HBoxContainer/Button' + String.num_int64(idx + 1))
		button.visible = false

func _select_choice(idx: int):
	#print(dialogueItem.choices[idx].leadsTo.entryId, ' what is going on')
	PlayerFinder.player.select_choice(dialogueItem.choices[idx])
	delete_choices()

func hide_textbox():
	visible = false
	delete_choices()

func show_text_instant():
	SpeakerText.visible_characters = len(SpeakerText.text)
	TextBoxText.visible_characters = len(TextBoxText.text)
	add_choices()

func _on_choice_button_pressed():
	print('PRESSED')
