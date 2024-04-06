extends Control
class_name SurgeChangesRow

@export var changeHeader: String = ''
@export_multiline var changeDetails: String = ''

@onready var changeTitle: RichTextLabel = get_node('HBoxContainer/ChangeTitle')
@onready var changeDetailsLabel: RichTextLabel = get_node('HBoxContainer/ChangeDetails')

func _ready():
	changeTitle.text = changeHeader
	changeDetailsLabel.text = changeDetails
