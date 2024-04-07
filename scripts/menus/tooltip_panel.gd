extends Control
class_name TooltipPanel

signal ok_pressed

@export var title: String = ''
@export var details: String = ''

@onready var titleLabel: RichTextLabel = get_node('Panel/TooltipTitle')
@onready var detailsLabel: RichTextLabel = get_node('Panel/TooltipDetails')
@onready var okButton: Button = get_node('Panel/OkButton')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed('game_decline'):
		get_viewport().set_input_as_handled()
		okButton.button_pressed = true

func initial_focus():
	okButton.grab_focus()

func load_tooltip_panel():
	visible = true
	initial_focus()
	titleLabel.text = '[center]' + title + '[/center]'
	detailsLabel.text = '[center]' + details + '[/center]'

func _on_ok_button_pressed():
	visible = false
	ok_pressed.emit()
