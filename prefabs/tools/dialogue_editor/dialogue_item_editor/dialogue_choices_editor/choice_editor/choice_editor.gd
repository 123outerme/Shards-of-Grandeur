extends Control
class_name ToolChoiceEditor

signal choice_button_label_changed(choiceIdx: int, label: String)
signal choice_button_delete_clicked(choiceIdx: int)
signal choice_button_leads_to_clicked(choiceIdx: int)
signal choice_button_turns_in_clicked(choiceIdx: int)

@export var dialogueItem: DialogueItem = null
@export var choiceIdx: int = -1
@export var questsDict: Dictionary[String, Quest] = {}

@onready var choiceLabel: LineEdit = get_node('Panel/ChoiceLabelControl/ChoiceLabel')
@onready var isDeclineChoiceCheck: CheckButton = get_node('Panel/IsDeclineChoiceControl/IsDeclineChoice')
@onready var leadsToButton: Button = get_node('Panel/LeadsToControl/LeadsToButton')
@onready var turnsInButton: Button = get_node('Panel/TurnsInControl/TurnsInButton')

func _ready() -> void:
	load_choice_editor()

func load_choice_editor() -> void:
	if dialogueItem != null and choiceIdx > -1:
		var choice: DialogueChoice = dialogueItem.choices[choiceIdx]
		choiceLabel.text = choice.choiceBtn
		isDeclineChoiceCheck.button_pressed = choice.isDeclineChoice
		if choice.leadsTo != null:
			leadsToButton.text = choice.leadsTo.entryId if choice.leadsTo.entryId != '' else choice.leadsTo.resource_path.get_file().get_basename()
		else:
			leadsToButton.text = '(No Entry)'
		if choice.turnsInQuest != '':
			var questPieces: PackedStringArray = choice.turnsInQuest.split('#')
			var questName: String = questPieces[0]
			var stepName: String = questPieces[1]
			turnsInButton.text = questName + ', ' + stepName

func _on_choice_label_text_changed(new_text: String) -> void:
	choice_button_label_changed.emit(choiceIdx, new_text)
	dialogueItem.choices[choiceIdx].choiceBtn = new_text

func _on_delete_button_pressed() -> void:
	choice_button_delete_clicked.emit(choiceIdx)

func _on_leads_to_button_pressed() -> void:
	choice_button_leads_to_clicked.emit(choiceIdx)

func _on_turns_in_button_pressed() -> void:
	choice_button_turns_in_clicked.emit(choiceIdx)

func _on_is_decline_choice_toggled(toggled_on: bool) -> void:
	dialogueItem.choices[choiceIdx].isDeclineChoice = toggled_on
