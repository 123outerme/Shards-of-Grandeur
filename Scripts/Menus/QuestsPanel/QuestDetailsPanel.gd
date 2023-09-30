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
@onready var rewardPanel: RewardPanel = get_node("Panel/StepDetailPanel/RewardPanel")
@onready var vboxViewport: VBoxContainer = get_node("Panel/ScrollContainer/VBoxContainer")
@onready var itemDetailsPanel: ItemDetailsPanel = get_node("ItemDetailsPanel")

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
	rewardPanel.reward = selectedStep.reward
	rewardPanel.load_reward_panel(itemDetailsPanel)
	
	for panel in get_tree().get_nodes_in_group("QuestStepPanel"):
		panel.queue_free()
	
	var questStepPanel = load("res://Prefabs/UI/Quests/QuestStepPanel.tscn")
	for step in questTracker.get_known_steps():
		var instantiatedPanel: QuestStepPanel = questStepPanel.instantiate()
		instantiatedPanel.step = step
		instantiatedPanel.questTracker = questTracker
		instantiatedPanel.detailsPanel = self
		vboxViewport.add_child(instantiatedPanel)

func hide_panel():
	itemDetailsPanel.visible = false
	visible = false

func _on_back_button_pressed():
	hide_panel()

func _on_item_sprite_button_pressed():
	itemDetailsPanel.visible = true
	itemDetailsPanel.load_item_details()
