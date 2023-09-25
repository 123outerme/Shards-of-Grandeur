extends Control
class_name QuestDetailsPanel

@export var questTracker: QuestTracker = null
var selectedStep: QuestStep = null

@onready var questName: RichTextLabel = get_node("Panel/QuestName")
@onready var questDescription: RichTextLabel = get_node("Panel/QuestDescription")
@onready var stepName: RichTextLabel = get_node("Panel/StepDetailPanel/StepName")
@onready var stepDescription: RichTextLabel = get_node("Panel/StepDetailPanel/StepDescription")
@onready var stepStatus: RichTextLabel = get_node("Panel/StepDetailPanel/StepStatus")
@onready var stepTurnIn: RichTextLabel = get_node("Panel/StepDetailPanel/StepTurnInTarget")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_quest_details()
	
func load_quest_details():
	if questTracker == null:
		return
	
	if selectedStep == null:
		selectedStep = questTracker.get_current_step()
	
	questName.text = '[center]' + questTracker.quest.questName + '[/center]'
	questDescription.text = '[center]' + questTracker.quest.description + '[/center]'
	stepName.text = '[center]' + selectedStep.name + '[/center]'
	stepDescription.text = selectedStep.description
	stepStatus.text = '[center]' + questTracker.get_step_status_str(selectedStep, true) + '[/center]'
	stepTurnIn.text = '[center]' + selectedStep.displayTurnInName + '[/center]'

func _on_back_button_pressed():
	visible = false
