extends Control
class_name ToolDialogueChoicesEditor

signal choice_leads_to_clicked(choiceIdx: int, dialogueItem: DialogueItem)
signal choices_editor_closed(dialogueItem: DialogueItem)

const CHOICE_EDITOR_SCENE = preload('res://prefabs/tools/dialogue_editor/dialogue_item_editor/dialogue_choices_editor/choice_editor/choice_editor.tscn')

@export var dialogueItem: DialogueItem = null
@export var questsDict: Dictionary[String, Quest] = {}

@onready var tabContainer: TabContainer = get_node('Panel/TabContainer')
@onready var entryQuestPicker: ToolEntryQuestPicker = get_node('EntryQuestPicker')

var nameOccurrences: Dictionary[String, Array] = {}

var questPickingChoiceIdx: int = -1

func _ready() -> void:
	load_choices_editor()

func load_choices_editor() -> void:
	entryQuestPicker.questsDict = questsDict
	nameOccurrences = {}
	for child: Node in tabContainer.get_children():
		child.visible = false
		tabContainer.remove_child(child)
		child.queue_free.call_deferred()
	
	if dialogueItem != null:
		for choiceIdx: int in range(len(dialogueItem.choices)):
			var choiceEditor: ToolChoiceEditor = CHOICE_EDITOR_SCENE.instantiate()
			choiceEditor.dialogueItem = dialogueItem
			choiceEditor.choiceIdx = choiceIdx
			choiceEditor.questsDict = questsDict
			choiceEditor.choice_button_label_changed.connect(_choice_button_label_changed)
			choiceEditor.choice_button_delete_clicked.connect(_choice_button_delete_clicked)
			choiceEditor.choice_button_leads_to_clicked.connect(_choice_button_leads_to_clicked)
			choiceEditor.choice_button_turns_in_clicked.connect(_choice_button_turns_in_clicked)
			var label: String = dialogueItem.choices[choiceIdx].choiceBtn
			if label == '':
				label = 'New Button'
			if not nameOccurrences.has(label):
				nameOccurrences[label] = [dialogueItem.choices[choiceIdx]]
			else:
				nameOccurrences[label].append(dialogueItem.choices[choiceIdx])
				label += ' (' + String.num_int64(len(nameOccurrences[label]) - 1) + ')'
			tabContainer.add_child(choiceEditor)
			choiceEditor.name = label
		visible = true

func _choice_button_label_changed(choiceIdx: int, label: String) -> void:
	if label == '':
		label = 'New Button'
	if not nameOccurrences.has(label):
		nameOccurrences[label] = [dialogueItem.choices[choiceIdx]]
	else:
		nameOccurrences[label].append(dialogueItem.choices[choiceIdx])
		label += ' (' + String.num_int64(len(nameOccurrences[label]) - 1) + ')'
	tabContainer.get_child(choiceIdx).name = label

func _choice_button_delete_clicked(choiceIdx: int) -> void:
	for idx: int in range(choiceIdx, len(dialogueItem.choices) - 1):
		dialogueItem.choices[idx] = dialogueItem.choices[idx + 1]
	dialogueItem.choices.pop_back()
	var choiceEditor: ToolChoiceEditor = tabContainer.get_child(choiceIdx)
	tabContainer.remove_child(choiceEditor)
	choiceEditor.queue_free.call_deferred()

func _choice_button_leads_to_clicked(choiceIdx: int):
	choice_leads_to_clicked.emit(choiceIdx, dialogueItem)

func _choice_button_turns_in_clicked(choiceIdx: int):
	questPickingChoiceIdx = choiceIdx
	entryQuestPicker.load_entry_quest_picker()

func _on_cancel_button_pressed() -> void:
	choices_editor_closed.emit(dialogueItem)
	visible = false

func _on_add_choice_button_pressed() -> void:
	var choice: DialogueChoice = DialogueChoice.new()
	if len(dialogueItem.choices) == 0:
		choice.isDeclineChoice = true # set decline choice true by default on the first one
	dialogueItem.choices.append(choice)
	load_choices_editor()

func _on_entry_quest_picker_set_entry_quest_and_step(quest: Quest, step: QuestStep) -> void:
	var choice: DialogueChoice = dialogueItem.choices[questPickingChoiceIdx]
	choice.turnsInQuest = quest.questName + '#' + step.name
	var choiceEditor: ToolChoiceEditor = tabContainer.get_child(questPickingChoiceIdx) as ToolChoiceEditor
	choiceEditor.load_choice_editor()
	questPickingChoiceIdx = -1

func _on_entry_quest_picker_set_entry_quest(quest: Quest) -> void:
	if quest == null:
		var choice: DialogueChoice = dialogueItem.choices[questPickingChoiceIdx]
		choice.turnsInQuest = ''
		var choiceEditor: ToolChoiceEditor = tabContainer.get_child(questPickingChoiceIdx) as ToolChoiceEditor
		choiceEditor.load_choice_editor()
		questPickingChoiceIdx = -1
