extends Control
class_name ToolDialogueLineEditor

signal preview_line_toggled(lineIdx: int, text: String)
signal delete_line_toggled(lineIdx: int)
signal min_show_secs_updated(lineIdx: int)

@export var dialogueItem: DialogueItem = null
@export var lineIdx: int = -1

@onready var textEdit: TextEdit = get_node('TextEdit')
@onready var minShowSecs: LineEdit = get_node('MinShowSecsControl/MinShowSecs')

func _ready() -> void:
	load_line_editor()

func load_line_editor() -> void:
	if dialogueItem != null and lineIdx > -1:
		textEdit.text = dialogueItem.lines[lineIdx]
		if len(dialogueItem.minShowSecs) > lineIdx:
			minShowSecs.text = String.num(dialogueItem.minShowSecs[lineIdx])
		else:
			minShowSecs.text = ''

func write_back_line_changes() -> void:
	dialogueItem.lines[lineIdx] = textEdit.text

func _on_preview_button_pressed() -> void:
	preview_line_toggled.emit(lineIdx, textEdit.text)

func _on_delete_button_pressed() -> void:
	delete_line_toggled.emit(lineIdx)

func _on_text_edit_text_changed() -> void:
	write_back_line_changes()

func _on_min_show_secs_text_changed(new_text: String) -> void:
	if not new_text.is_valid_float():
		if len(dialogueItem.minShowSecs) > lineIdx:
			minShowSecs.text = String.num(dialogueItem.minShowSecs[lineIdx])
		return
	
	if len(dialogueItem.minShowSecs) <= lineIdx:
		dialogueItem.minShowSecs.resize(lineIdx + 1)
		dialogueItem.minShowSecs.fill(0)
	dialogueItem.minShowSecs[lineIdx] = new_text.to_float()
	min_show_secs_updated.emit(lineIdx)
