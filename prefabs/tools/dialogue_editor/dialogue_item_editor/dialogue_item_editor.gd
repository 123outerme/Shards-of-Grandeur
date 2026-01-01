extends Control
class_name ToolDialogueItemEditor

signal preview_line_toggled(dialogueItem: DialogueItem, lineIdx: int, text: String)
signal edit_choices_toggled(dialogueItem: DialogueItem)
signal delete_item_pressed(dialogueItem: DialogueItem)

const DIALOGUE_LINE_EDITOR_SCENE = preload("res://prefabs/tools/dialogue_editor/dialogue_item_editor/dialogue_line_editor/dialogue_line_editor.tscn")
const SFX_BUTTON_SCENE = preload("res://prefabs/ui/sfx_button.tscn")

@export var dialogueItem: DialogueItem = null

@onready var vBox: VBoxContainer = get_node('ScrollContainer/VBoxContainer')
@onready var hBox: HBoxContainer = get_node('ScrollContainer2/HBoxContainer')
@onready var speakerAnimLineEdit: LineEdit = get_node('SpeakerAnim')
@onready var speakerOverrideLineEdit: LineEdit = get_node('SpeakerOverride')

var lineEditors: Array[ToolDialogueLineEditor] = []

func _ready() -> void:
	load_item_editor()

func load_item_editor() -> void:
	for child: Node in vBox.get_children():
		child.visible = false
		child.queue_free()
	for child: Node in hBox.get_children():
		child.visible = false
		child.queue_free()
	
	if dialogueItem != null:
		for lineIdx: int in range(len(dialogueItem.lines)):
			instantiate_line_editor(lineIdx)
		for choiceIdx: int in range(len(dialogueItem.choices)):
			instantiate_choice_button(choiceIdx)
		speakerAnimLineEdit.text = dialogueItem.animation
		speakerOverrideLineEdit.text = dialogueItem.speakerOverride

func instantiate_line_editor(idx: int) -> ToolDialogueLineEditor:
	var lineEditor: ToolDialogueLineEditor = DIALOGUE_LINE_EDITOR_SCENE.instantiate()
	lineEditor.dialogueItem = dialogueItem
	lineEditor.lineIdx = idx
	lineEditor.preview_line_toggled.connect(_preview_line)
	lineEditor.min_show_secs_updated.connect(_min_show_secs_updated)
	lineEditor.delete_line_pressed.connect(_delete_line)
	vBox.add_child(lineEditor)
	if len(lineEditors) > 0:
		var lastEditor: ToolDialogueLineEditor = lineEditors.back()
		lastEditor.textEdit.focus_next = lastEditor.textEdit.get_path_to(lineEditor.textEdit)
		lineEditor.textEdit.focus_previous = lineEditor.textEdit.get_path_to(lastEditor.textEdit)
	lineEditors.append(lineEditor)
	return lineEditor

func instantiate_choice_button(idx: int) -> void:
	var button: Button = SFX_BUTTON_SCENE.instantiate()
	button.text = dialogueItem.choices[idx].choiceBtn
	button.custom_minimum_size = dialogueItem.choices[idx].buttonDims
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.focus_mode = Control.FOCUS_NONE
	hBox.add_child(button)

func write_back_line_changes() -> void:
	for lineEditor: ToolDialogueLineEditor in lineEditors:
		dialogueItem.write_back_line_changes()

func _preview_line(lIdx: int, text: String) -> void:
	preview_line_toggled.emit(dialogueItem, lIdx, text)

func _min_show_secs_updated(lineIdx: int) -> void:
	for idx: int in range(0, lineIdx):
		lineEditors[idx].load_line_editor()

func _delete_line(lIdx: int) -> void:
	for idx: int in range(lIdx, len(dialogueItem.lines) - 1):
		dialogueItem.lines[idx] = dialogueItem.lines[idx + 1]
		lineEditors[idx].load_line_editor()
	dialogueItem.lines.pop_back()
	var lastLineEditor: ToolDialogueLineEditor = lineEditors.pop_back()
	lastLineEditor.visible = false
	lastLineEditor.queue_free()
	if len(lineEditors) > 0:
		lineEditors.back().textEdit.focus_next = ''

func _on_add_line_button_pressed() -> void:
	dialogueItem.lines.append('')
	instantiate_line_editor(len(dialogueItem.lines) - 1)

func _on_edit_choices_button_pressed() -> void:
	edit_choices_toggled.emit(dialogueItem)

func _on_speaker_anim_text_changed(new_text: String) -> void:
	dialogueItem.animation = new_text

func _on_speaker_override_text_changed(new_text: String) -> void:
	dialogueItem.speakerOverride = new_text

func _on_delete_item_button_pressed() -> void:
	delete_item_pressed.emit(dialogueItem)
