extends Node2D
class_name QuestsMenu

signal back_pressed
signal turn_in_step_to(saveName: String)
signal level_up(newLevels: int)
signal act_changed

@export_category("Quests Panel - Filters")

@export var selectedFilter: QuestTracker.Status = QuestTracker.Status.ALL

## if not == '', is the name of the entity to turn quests into
@export var turnInTargetName: String = ''

## if true, the player cannot change the selected filter
@export var lockFilters: bool = false

const FILTER_BUTTON_TYPES_ORDER: Array[QuestTracker.Status] = [
	QuestTracker.Status.ALL,
	QuestTracker.Status.MAIN_QUEST,
	QuestTracker.Status.IN_PROGRESS,
	QuestTracker.Status.READY_TO_TURN_IN_STEP,
	QuestTracker.Status.COMPLETED,
	QuestTracker.Status.INCOMPLETE,
	QuestTracker.Status.FAILED
]

var rewardNewLvs: int = 0

var lastFocused: Control = null
var lastInteractedTracker: QuestTracker = null

var FILTER_BUTTONS: Array[Button] = []

var questSlotPanels: Array[QuestSlotPanel] = []
var questSlotPanelsByTracker: Dictionary[QuestTracker, QuestSlotPanel] = {}

@onready var questsPanelControl: Control = get_node('QuestsPanel')

@onready var questsTitle: RichTextLabel = get_node("QuestsPanel/Panel/QuestsTitle")
@onready var actTitle: RichTextLabel = get_node("QuestsPanel/Panel/ActTitle")

@onready var allButton: Button = get_node('QuestsPanel/Panel/HBoxContainer/AllButton')
@onready var mainQuestButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/MainQuestButton")
@onready var inProgressButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/InProgressButton")
@onready var readyToTurnInButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/ReadyToTurnInButton")
@onready var completedButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/CompletedButton")
@onready var notCompletedButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/NotCompletedButton")
@onready var failedButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/FailedButton")

@onready var scrollContainer: ScrollContainer = get_node('QuestsPanel/Panel/ScrollContainer')
@onready var vboxViewport: VBoxContainer = get_node("QuestsPanel/Panel/ScrollContainer/VBoxContainer")
@onready var backButton: Button = get_node("QuestsPanel/Panel/BackButton")
@onready var questDetailsPanel: QuestDetailsPanel = get_node("QuestDetailsPanel")
@onready var questRewardPanel: QuestRewardPanel = get_node("QuestRewardPanel")

# Called when the node enters the scene tree for the first time.
func _ready():
	FILTER_BUTTONS = [
		allButton,
		mainQuestButton,
		inProgressButton,
		readyToTurnInButton,
		completedButton,
		notCompletedButton,
		failedButton
	]

func _unhandled_input(event):
	if visible and event.is_action_pressed('game_decline'):
		get_viewport().set_input_as_handled()
		toggle()
	
	if visible and (event.is_action_pressed('game_tab_left') or event.is_action_pressed('game_tab_right')):
		get_viewport().set_input_as_handled()
		var selectedTypeIdx: int = FILTER_BUTTON_TYPES_ORDER.find(selectedFilter)
		var direction: int = -1 if event.is_action_pressed('game_tab_left') else 1
		# get next filter button to the left (negative)/right (positive) that's not disabled (wrapping around)
		var newTypeIdx: int = wrapi(selectedTypeIdx + direction, 0, len(FILTER_BUTTON_TYPES_ORDER))
		while selectedTypeIdx != newTypeIdx:
			if FILTER_BUTTONS[newTypeIdx] != null and not FILTER_BUTTONS[newTypeIdx].disabled:
				break
			newTypeIdx = wrapi((newTypeIdx + direction), 0, len(FILTER_BUTTON_TYPES_ORDER))
		filter_by(FILTER_BUTTON_TYPES_ORDER[newTypeIdx])
		if FILTER_BUTTONS[newTypeIdx] != null:
			FILTER_BUTTONS[newTypeIdx].grab_focus()

func toggle():
	visible = not visible
	if visible:
		load_quests_panel(true, true)
		initial_focus()
	else:
		if questDetailsPanel.visible:
			questDetailsPanel.hide_panel(false)
			questsPanelControl.visible = true
		backButton.disabled = false
		back_pressed.emit()

func initial_focus():
	var centerMostFilter = get_centermost_filter()
	if centerMostFilter != null:
		centerMostFilter.grab_focus()
		return
	
	backButton.grab_focus()

func get_centermost_filter() -> Button:
	if not readyToTurnInButton.disabled:
		return readyToTurnInButton
	
	if not inProgressButton.disabled:
		return inProgressButton
	
	if not completedButton.disabled:
		return completedButton
	
	if not mainQuestButton.disabled:
		return mainQuestButton
	
	if not notCompletedButton.disabled:
		return notCompletedButton
	
	return allButton
	# Failed would come after, but All is always enabled

func restore_previous_focus(controlProperty: String):
	get_last_focused_panel()
	if lastFocused == null:
		initial_focus()
	else:
		lastFocused[controlProperty].grab_focus()

func get_last_focused_panel():
	lastFocused = null
	for panel in get_tree().get_nodes_in_group("QuestSlotPanel"):
		if panel.questTracker == lastInteractedTracker:
			lastFocused = panel

func load_quests_panel(rebuild: bool = false, fromToggle: bool = false):
	PlayerResources.questInventory.auto_update_quests() # update collect quests
	update_filter_buttons()
	backButton.focus_neighbor_top = backButton.get_path_to(get_centermost_filter())
	if rebuild:
		# All is never disabled
		allButton.focus_neighbor_bottom = allButton.get_path_to(backButton)
		allButton.focus_neighbor_top = allButton.get_path_to(backButton)
		# lock all filter buttons to be unlocked when creating quest slot panels
		mainQuestButton.disabled = true
		mainQuestButton.focus_neighbor_bottom = mainQuestButton.get_path_to(backButton)
		mainQuestButton.focus_neighbor_top = mainQuestButton.get_path_to(backButton)
		
		inProgressButton.disabled = true
		inProgressButton.focus_neighbor_bottom = inProgressButton.get_path_to(backButton)
		inProgressButton.focus_neighbor_top = inProgressButton.get_path_to(backButton)
		
		readyToTurnInButton.disabled = true
		readyToTurnInButton.focus_neighbor_bottom = readyToTurnInButton.get_path_to(backButton)
		readyToTurnInButton.focus_neighbor_top = readyToTurnInButton.get_path_to(backButton)
		
		completedButton.disabled = true
		completedButton.focus_neighbor_bottom = inProgressButton.get_path_to(backButton)
		completedButton.focus_neighbor_top = inProgressButton.get_path_to(backButton)
		
		notCompletedButton.disabled = true
		notCompletedButton.focus_neighbor_bottom = notCompletedButton.get_path_to(backButton)
		notCompletedButton.focus_neighbor_top = notCompletedButton.get_path_to(backButton)
		
		failedButton.disabled = true
		failedButton.focus_neighbor_bottom = failedButton.get_path_to(backButton)
		failedButton.focus_neighbor_top = failedButton.get_path_to(backButton)
		
		for panel: QuestSlotPanel in questSlotPanels:
			panel.queue_free()
		questSlotPanels = []
		questSlotPanelsByTracker = {}
	
		var questSlotPanel = load("res://prefabs/ui/quests/quest_slot_panel.tscn")
		for questTracker: QuestTracker in PlayerResources.questInventory.get_sorted_trackers():
			var trackerStatus: QuestTracker.Status = questTracker.get_current_status()
			var instantiatedPanel: QuestSlotPanel = questSlotPanel.instantiate()
			instantiatedPanel.questTracker = questTracker
			instantiatedPanel.turnInName = turnInTargetName
			instantiatedPanel.questsMenu = self
			questSlotPanels.append(instantiatedPanel)
			questSlotPanelsByTracker[questTracker] = instantiatedPanel
			if questTracker.quest.isMainQuest:
				mainQuestButton.disabled = lockFilters
			if trackerStatus == QuestTracker.Status.IN_PROGRESS:
				inProgressButton.disabled = lockFilters
			if trackerStatus == QuestTracker.Status.READY_TO_TURN_IN_STEP:
				readyToTurnInButton.disabled = lockFilters
			if trackerStatus == QuestTracker.Status.COMPLETED:
				completedButton.disabled = lockFilters
			else: # if not completed
				notCompletedButton.disabled = lockFilters
			if trackerStatus == QuestTracker.Status.FAILED:
				failedButton.disabled = lockFilters
		
	
	var firstPanel: QuestSlotPanel = null
	var lastPanel: QuestSlotPanel = null
	#for panel: QuestSlotPanel in questSlotPanels:
	for questTracker in PlayerResources.questInventory.get_sorted_trackers():
		var panel: QuestSlotPanel = null
		if questSlotPanelsByTracker.has(questTracker):
			panel = questSlotPanelsByTracker[questTracker]
		else:
			continue
		if vboxViewport.get_children().has(panel):
			vboxViewport.remove_child(panel)
		var trackerStatus: QuestTracker.Status = panel.questTracker.get_current_status()
		if selectedFilter == QuestTracker.Status.ALL or selectedFilter == trackerStatus \
					or (selectedFilter == QuestTracker.Status.INCOMPLETE and trackerStatus != QuestTracker.Status.COMPLETED and trackerStatus != QuestTracker.Status.FAILED) \
					or (selectedFilter == QuestTracker.Status.MAIN_QUEST and panel.questTracker.quest.isMainQuest):
			if firstPanel == null:
				firstPanel = panel
			panel.turnInName = turnInTargetName
			vboxViewport.add_child(panel)
			if trackerStatus == QuestTracker.Status.READY_TO_TURN_IN_STEP and turnInTargetName in panel.questTracker.get_current_step().turnInNames and fromToggle:
				panel.turnInButton.call_deferred('grab_focus')
			panel.load_quest_slot_panel()
			if lastPanel != null:
				panel.connect_focus_to_above_panel.call_deferred(lastPanel)
			lastPanel = panel
	if firstPanel != null:
		allButton.focus_neighbor_bottom = allButton.get_path_to(firstPanel.detailsButton)
		mainQuestButton.focus_neighbor_bottom = mainQuestButton.get_path_to(firstPanel.detailsButton)
		inProgressButton.focus_neighbor_bottom = inProgressButton.get_path_to(firstPanel.detailsButton)
		readyToTurnInButton.focus_neighbor_bottom = readyToTurnInButton.get_path_to(firstPanel.detailsButton)
		completedButton.focus_neighbor_bottom = completedButton.get_path_to(firstPanel.detailsButton)
		notCompletedButton.focus_neighbor_bottom = notCompletedButton.get_path_to(firstPanel.detailsButton)
		failedButton.focus_neighbor_bottom = failedButton.get_path_to(firstPanel.detailsButton)
		firstPanel.detailsButton.focus_neighbor_top = firstPanel.detailsButton.get_path_to(get_centermost_filter())
		firstPanel.turnInButton.focus_neighbor_top = firstPanel.turnInButton.get_path_to(get_centermost_filter())
		firstPanel.pinButton.focus_neighbor_top = firstPanel.pinButton.get_path_to(get_centermost_filter())
	if lastPanel != null:
		# set the last panel's bottom neighbor to be the back button
		lastPanel.detailsButton.focus_neighbor_bottom = lastPanel.detailsButton.get_path_to(backButton)
		lastPanel.turnInButton.focus_neighbor_bottom = lastPanel.turnInButton.get_path_to(backButton)
		lastPanel.pinButton.focus_neighbor_bottom = lastPanel.pinButton.get_path_to(backButton)
		
		# set the back button's top neighbor to be the last panel's details button
		backButton.focus_neighbor_top = backButton.get_path_to(lastPanel.detailsButton)
	backButton.focus_neighbor_bottom = backButton.get_path_to(get_centermost_filter())
		
	if turnInTargetName != '':
		questsTitle.text = '[center]Turn In Quests[/center]'
	else:
		questsTitle.text = '[center]Quests[/center]'
			
	actTitle.text = '[center]Act ' + String.num_int64(PlayerResources.questInventory.currentAct) + ':\n' + PlayerResources.questInventory.actNames[PlayerResources.questInventory.currentAct] + '[/center]'

func update_filter_buttons():
	allButton.button_pressed = selectedFilter == QuestTracker.Status.ALL
	mainQuestButton.button_pressed = selectedFilter == QuestTracker.Status.MAIN_QUEST
	inProgressButton.button_pressed = selectedFilter == QuestTracker.Status.IN_PROGRESS
	readyToTurnInButton.button_pressed = selectedFilter == QuestTracker.Status.READY_TO_TURN_IN_STEP
	completedButton.button_pressed = selectedFilter == QuestTracker.Status.COMPLETED
	notCompletedButton.button_pressed = selectedFilter == QuestTracker.Status.INCOMPLETE
	failedButton.button_pressed = selectedFilter == QuestTracker.Status.FAILED

func filter_by(type: QuestTracker.Status = QuestTracker.Status.ALL):
	if type != selectedFilter: # if changed, reset scroll
		scrollContainer.scroll_vertical = 0
	selectedFilter = type
	load_quests_panel()

func pin_button_pressed(questTracker: QuestTracker):
	lastInteractedTracker = questTracker
	load_quests_panel()
	restore_previous_focus('pinButton')

func turn_in(questTracker: QuestTracker):
	lastInteractedTracker = questTracker
	questRewardPanel.reward = questTracker.get_current_step().reward
	var curAct: int = PlayerResources.questInventory.currentAct
	rewardNewLvs = PlayerResources.questInventory.turn_in_cur_step(questTracker)
	if curAct != PlayerResources.questInventory.currentAct:
		act_changed.emit()
	turn_in_step_to.emit(turnInTargetName)
	load_quests_panel(true, true) # not from the toggle function, but will focus any other quests that can be turned in
	questRewardPanel.load_quest_reward_panel()
	backButton.disabled = true
	
func show_details(questTracker: QuestTracker):
	lastInteractedTracker = questTracker
	backButton.disabled = true
	questDetailsPanel.questTracker = questTracker
	questDetailsPanel.visible = true
	questsPanelControl.visible = false
	questDetailsPanel.load_quest_details()

func _on_all_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		filter_by(QuestTracker.Status.ALL)
	elif selectedFilter == QuestTracker.Status.ALL:
		allButton.button_pressed = true # if deselecting and All is already being filtered on, re-select

func _on_main_quests_button_toggled(toggled_on: bool) -> void:
	if toggled_on:
		filter_by(QuestTracker.Status.MAIN_QUEST)
	elif selectedFilter == QuestTracker.Status.MAIN_QUEST:
		filter_by()

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

func _on_failed_button_toggled(button_pressed):
	if button_pressed:
		filter_by(QuestTracker.Status.FAILED)
	elif selectedFilter == QuestTracker.Status.FAILED:
		filter_by()

func _on_back_button_pressed():
	toggle()

func _on_quest_reward_panel_ok_pressed():
	backButton.disabled = false
	if rewardNewLvs > 0:
		level_up.emit(rewardNewLvs)
	else:
		_on_back_button_pressed()

func _on_quest_details_panel_panel_hidden():
	backButton.disabled = false
	questsPanelControl.visible = true
	restore_previous_focus('detailsButton')
