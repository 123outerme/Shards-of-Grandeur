extends Node2D
class_name TextBox

var chars_per_sec: float = 40
var text_visible_chars_partial: float = 0

var speaker_chars_per_sec: float = 40
var speaker_visible_chars_partial: float = 0

@onready var TextBoxText: RichTextLabel = get_node("TextContainer/MarginContainer/VBoxContainer/TextBoxText")
@onready var SpeakerText: RichTextLabel = get_node("TextContainer/MarginContainer/VBoxContainer/SpeakerText")
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
			ReadySprite.visible = true
	pass

func set_textbox_text(text: String, speaker: String):
	advance_textbox(text)
	SpeakerText.text = speaker + ":"
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

func hide_textbox():
	visible = false

func show_text_instant():
	SpeakerText.visible_characters = len(SpeakerText.text)
	TextBoxText.visible_characters = len(TextBoxText.text)
