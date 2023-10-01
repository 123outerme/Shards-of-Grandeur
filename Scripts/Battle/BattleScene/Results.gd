extends Control
class_name Results

@export var battleUI: BattleUI

@onready var textBoxText: RichTextLabel = get_node("TextBoxText")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func show_text(newText: String):
	textBoxText.text = newText

func _on_ok_button_pressed():
	pass # Replace with function body.
