extends Control
class_name QuestDetailsPanel
signal panel_hidden

@export var questTracker: QuestTracker = null
var selectedStep: QuestStep = null

@onready var questName: RichTextLabel = get_node("Panel/QuestName")
@onready var questDescription: RichTextLabel = get_node("Panel/QuestDescription")
@onready var stepName: RichTextLabel = get_node("Panel/StepDetailPanel/StepName")
@onready var stepDescription: RichTextLabel = get_node("Panel/StepDetailPanel/StepDescription")
@onready var stepStatus: RichTextLabel = get_node("Panel/StepDetailPanel/StepStatus")
@onready var turnInLabel: RichTextLabel = get_node("Panel/StepDetailPanel/TurnInTo")
@onready var stepTurnIn: RichTextLabel = get_node("Panel/StepDetailPanel/StepTurnInTarget")
@onready var rewardPanel: RewardPanel = get_node("Panel/StepDetailPanel/RewardPanel")
@onready var scrollContainer: ScrollContainer = get_node("Panel/ScrollContainer")
@onready var vboxViewport: VBoxContainer = get_node("Panel/ScrollContainer/VBoxContainer")
@onready var itemDetailsPanel: ItemDetailsPanel = get_node("ItemDetailsPanel")
@onready var backButton: Button = get_node("Panel/BackButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_quest_details()

func initial_focus():
	backButton.grab_focus()

func restore_previous_focus():
	if selectedStep == null:
		initial_focus()
	else:
		for panel in get_tree().get_nodes_in_group("QuestStepPanel"):
			if panel.step == selectedStep:
				panel.viewButton.grab_focus()

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
	if selectedStep.displayTurnInName != '':
		stepTurnIn.text = '[center]' + selectedStep.displayTurnInName + '[/center]'
		stepTurnIn.visible = true
		turnInLabel.visible = true
	else:
		stepTurnIn.visible = false
		turnInLabel.visible = false
	rewardPanel.reward = selectedStep.reward
	rewardPanel.load_reward_panel()
	
	for panel in get_tree().get_nodes_in_group("QuestStepPanel"):
		panel.queue_free()
	
	var questStepPanel = load("res://prefabs/ui/quests/quest_step_panel.tscn")
	for step in questTracker.get_known_steps():
		var instantiatedPanel: QuestStepPanel = questStepPanel.instantiate()
		instantiatedPanel.step = step
		instantiatedPanel.questTracker = questTracker
		instantiatedPanel.detailsPanel = self
		vboxViewport.add_child(instantiatedPanel)
	restore_previous_focus()

func hide_panel():
	itemDetailsPanel.visible = false
	visible = false
	panel_hidden.emit()

func _on_back_button_pressed():
	hide_panel()

func _on_item_details_panel_back_pressed():
	rewardPanel.itemSpriteBtn.grab_focus()

func _on_reward_panel_show_item_details(item):
	itemDetailsPanel.item = item
	itemDetailsPanel.count = 0
	itemDetailsPanel.load_item_details()
	itemDetailsPanel.visible = true
