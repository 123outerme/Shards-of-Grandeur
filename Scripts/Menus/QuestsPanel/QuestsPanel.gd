extends Node2D
class_name QuestsMenu

signal back_pressed
signal turn_in_step_to(saveName: String)
signal level_up(newLevels: int)

@export_category("Quests Panel - Filters")
@export var selectedFilter: QuestTracker.Status = QuestTracker.Status.ALL
@export var turnInTargetName: String = ''
@export var lockFilters: bool = false

var rewardNewLvs: int = 0
var actNames: Array[String] = [
	'Prologue', # act 0
	'act1placeholder', # act 1
	'act2placeholder', # act 2
	'act3placeholder', # act 3
	'act4placeholder', # act 4
]

@onready var questsTitle: RichTextLabel = get_node("QuestsPanel/Panel/QuestsTitle")
@onready var actTitle: RichTextLabel = get_node("QuestsPanel/Panel/ActTitle")
@onready var inProgressButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/InProgressButton")
@onready var readyToTurnInButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/ReadyToTurnInButton")
@onready var completedButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/CompletedButton")
@onready var notCompletedButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/NotCompletedButton")
@onready var vboxViewport: VBoxContainer = get_node("QuestsPanel/Panel/ScrollContainer/VBoxContainer")
@onready var backButton: Button = get_node("QuestsPanel/Panel/BackButton")
@onready var questDetailsPanel: QuestDetailsPanel = get_node("QuestDetailsPanel")
@onready var questRewardPanel: QuestRewardPanel = get_node("QuestRewardPanel")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func toggle():
	visible = not visible
	if visible:
		load_quests_panel()
		initial_focus()
	else:
		questDetailsPanel.hide_panel()
		back_pressed.emit()

func initial_focus():
	if not inProgressButton.disabled:
		inProgressButton.grab_focus()
		return
	
	if not readyToTurnInButton.disabled:
		readyToTurnInButton.grab_focus()
		return
		
	if not completedButton.disabled:
		completedButton.grab_focus()
		return
	
	backButton.grab_focus()

func load_quests_panel():
	PlayerResources.questInventory.update_collect_quests() # update collect quests
	update_filter_buttons()
	# lock all filter buttons to be unlocked when creating quest slot panels
	inProgressButton.disabled = true
	readyToTurnInButton.disabled = true
	completedButton.disabled = true
	notCompletedButton.disabled = true
	
	for panel in get_tree().get_nodes_in_group("QuestSlotPanel"):
		panel.queue_free()
	
	var questSlotPanel = load("res://Prefabs/UI/Quests/QuestSlotPanel.tscn")
	for questTracker in PlayerResources.questInventory.quests:
		if selectedFilter == QuestTracker.Status.ALL or selectedFilter == questTracker.get_current_status() or (selectedFilter == QuestTracker.Status.INCOMPLETE and questTracker.get_current_status() != QuestTracker.Status.COMPLETED):
			var instantiatedPanel: QuestSlotPanel = questSlotPanel.instantiate()
			instantiatedPanel.questTracker = questTracker
			instantiatedPanel.turnInName = turnInTargetName
			instantiatedPanel.questsMenu = self
			vboxViewport.add_child(instantiatedPanel)
		if questTracker.get_current_status() == QuestTracker.Status.IN_PROGRESS:
			inProgressButton.disabled = lockFilters
		if questTracker.get_current_status() == QuestTracker.Status.READY_TO_TURN_IN_STEP:
			readyToTurnInButton.disabled = lockFilters
		if questTracker.get_current_status() == QuestTracker.Status.COMPLETED:
			completedButton.disabled = lockFilters
		else: # if not completed
			notCompletedButton.disabled = lockFilters
		
	if turnInTargetName != '':
		questsTitle.text = '[center]Turn In Quests[/center]'
	else:
		questsTitle.text = '[center]Quests[/center]'
			
	actTitle.text = 'Act ' + String.num(PlayerResources.questInventory.currentAct) + ': ' + actNames[PlayerResources.questInventory.currentAct]

func update_filter_buttons():
	inProgressButton.button_pressed = selectedFilter == QuestTracker.Status.IN_PROGRESS
	readyToTurnInButton.button_pressed = selectedFilter == QuestTracker.Status.READY_TO_TURN_IN_STEP
	completedButton.button_pressed = selectedFilter == QuestTracker.Status.COMPLETED
	notCompletedButton.button_pressed = selectedFilter == QuestTracker.Status.INCOMPLETE

func filter_by(type: QuestTracker.Status = QuestTracker.Status.ALL):
	selectedFilter = type
	load_quests_panel()

func turn_in(questTracker: QuestTracker):
	questRewardPanel.reward = questTracker.get_current_step().reward
	questRewardPanel.load_quest_reward_panel()
	backButton.disabled = true
	rewardNewLvs = PlayerResources.questInventory.turn_in_cur_step(questTracker)
	turn_in_step_to.emit(turnInTargetName)
	load_quests_panel()
	
func show_details(questTracker: QuestTracker):
	backButton.disabled = true
	questDetailsPanel.questTracker = questTracker
	questDetailsPanel.visible = true
	questDetailsPanel.selectedStep = null
	questDetailsPanel.load_quest_details()

func _on_in_progress_button_toggled(button_pressed):
	if button_pressed:
		filter_by(QuestTracker.Status.IN_PROGRESS)
	elif selectedFilter == QuestTracker.Status.IN_PROGRESS:
		filter_by()

func _on_ready_to_turn_in_button_toggled(button_pressed):
	if button_pressed:
		filter_by(QuestTracker.Status.READY_TO_TURN_IN_STEP)
	elif selectedFilter == QuestTracker.Status.READY_TO_TURN_IN_STEP:
		filter_by()

func _on_completed_button_toggled(button_pressed):
	if button_pressed:
		filter_by(QuestTracker.Status.COMPLETED)
	elif selectedFilter == QuestTracker.Status.COMPLETED:
		filter_by()
		
func _on_not_completed_button_toggled(button_pressed):
	if button_pressed:
		filter_by(QuestTracker.Status.INCOMPLETE)
	elif selectedFilter == QuestTracker.Status.INCOMPLETE:
		filter_by()
	
func _on_back_button_pressed():
	toggle()

func _on_quest_details_back_button_pressed():
	backButton.disabled = false
	initial_focus()

func _on_quest_reward_panel_ok_pressed():
	backButton.disabled = false
	initial_focus()
	if rewardNewLvs > 0:
		level_up.emit(rewardNewLvs)
