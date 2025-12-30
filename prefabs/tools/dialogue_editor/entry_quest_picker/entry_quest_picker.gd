extends Control
class_name ToolEntryQuestPicker

signal set_entry_quest(quest: Quest)
signal set_entry_quest_and_step(quest: Quest, step: QuestStep)
signal cancel_set_entry_quest

enum ToolEntryQuestPickerMenuState {
	PICK_QUEST,
	PICK_STEP
}

const SFX_BUTTON_SCENE = preload('res://prefabs/ui/sfx_button.tscn')

@export var questsDict: Dictionary[String, Quest]
@export var picksStep = false

@onready var hflowContainer: HFlowContainer = get_node('Panel/ScrollContainer/HFlowContainer')

var state: ToolEntryQuestPickerMenuState = ToolEntryQuestPickerMenuState.PICK_QUEST
var questPicked: Quest = null

func load_entry_quest_picker(restart: bool = true) -> void:
	for child: Node in hflowContainer.get_children():
		child.visible = false
		child.queue_free()
	
	if restart:
		state = ToolEntryQuestPickerMenuState.PICK_QUEST
		questPicked = null
	if state == ToolEntryQuestPickerMenuState.PICK_QUEST:
		for quest: Quest in questsDict.values():
			var button: Button = SFX_BUTTON_SCENE.instantiate()
			button.pressed.connect(_quest_picked.bind(quest))
			button.text = quest.questName
			hflowContainer.add_child(button)
		visible = true
	elif state == ToolEntryQuestPickerMenuState.PICK_STEP and questPicked != null:
		for step: QuestStep in questPicked.steps:
			var button: Button = SFX_BUTTON_SCENE.instantiate()
			button.pressed.connect(_step_picked.bind(step))
			button.text = step.name
			hflowContainer.add_child(button)

func unload_entry_quest_picker() -> void:
	for child: Node in hflowContainer.children():
		child.queue_free()
	questPicked = null
	state = ToolEntryQuestPickerMenuState.PICK_QUEST
	visible = false

func _quest_picked(quest: Quest) -> void:
	if not picksStep:
		set_entry_quest.emit(quest)
		unload_entry_quest_picker()
	else:
		questPicked = quest
		state = ToolEntryQuestPickerMenuState.PICK_STEP
		load_entry_quest_picker(false)

func _step_picked(step: QuestStep) -> void:
	set_entry_quest_and_step.emit(questPicked, step)
	unload_entry_quest_picker()

func _on_no_quest_button_pressed() -> void:
	set_entry_quest.emit(null)
	unload_entry_quest_picker()

func _on_cancel_button_pressed() -> void:
	if questPicked == null:
		cancel_set_entry_quest.emit()
		unload_entry_quest_picker()
	else:
		questPicked = null
		load_entry_quest_picker()
