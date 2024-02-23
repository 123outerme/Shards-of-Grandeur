extends Panel
class_name QuestStepPanel

@export var step: QuestStep = null
@export var questTracker: QuestTracker = null
@export var detailsPanel: QuestDetailsPanel = null

@onready var stepName: RichTextLabel = get_node("CenterStepName/StepName")
@onready var stepProgress: RichTextLabel = get_node("CenterStepProgress/StepProgress")
@onready var viewButton: Button = get_node("CenterButtons/HBoxContainer/ViewButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_quest_step_panel()

func load_quest_step_panel():
	if step == null or questTracker == null or detailsPanel == null:
		return
	
	stepName.text = step.name
	stepProgress.text = '[center]' + questTracker.get_step_status_str(step) + '[/center]'
	viewButton.disabled = detailsPanel.selectedPanel.step == step

func _on_view_button_pressed():
	detailsPanel.selectedPanel = self
	detailsPanel.load_quest_details(false)
