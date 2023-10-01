extends RichTextLabel
class_name TextBoxText

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func show_text(newText: String):
	text = newText
