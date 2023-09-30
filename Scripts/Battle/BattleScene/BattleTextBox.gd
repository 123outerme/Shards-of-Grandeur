extends Node2D

@export var state = ''

@onready var textBoxText: RichTextLabel = get_node("TextContainer/MarginContainer/TextBoxText")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func show_text(text: String):
	textBoxText.text = text
