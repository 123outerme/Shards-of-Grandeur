extends Control
class_name ToolDialogueLineEditor

signal preview_line_toggled(lineIdx: int, text: String)
signal delete_line_pressed(lineIdx: int)

@export var dialogueItem: DialogueItem = null
@export var lineIdx: int = -1

@onready var textEdit: TextEdit = get_node('TextEdit')

func _ready() -> void:
	load_line_editor()

func load_line_editor() -> void:
	if dialogueItem != null and lineIdx > -1:
		textEdit.text = dialogueItem.lines[lineIdx]

func write_back_line_changes() -> void:
	dialogueItem.lines[lineIdx] = textEdit.text

func _on_preview_button_pressed() -> void:
	preview_line_toggled.emit(lineIdx, textEdit.text)

func _on_delete_button_pressed() -> void:
	delete_line_pressed.emit(lineIdx)

func _on_text_edit_text_changed() -> void:
	write_back_line_changes()
