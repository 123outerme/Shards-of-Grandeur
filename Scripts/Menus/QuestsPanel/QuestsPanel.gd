extends Node2D
class_name QuestsMenu

@export_category("Quests Panel - Filters")
@export var selectedFilter: QuestTracker.Status
@export var turnInTargetName: String
@export var lockFilters: bool = false

@onready var questsTitle: RichTextLabel = get_node("QuestsPanel/Panel/QuestsTitle")
@onready var inProgressButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/InProgressButton")
@onready var readyToTurnInButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/ReadyToTurnInButton")
@onready var completedButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/CompletedButton")
@onready var notCompletedButton: Button = get_node("QuestsPanel/Panel/HBoxContainer/NotCompletedButton")
@onready var vboxViewport: VBoxContainer = get_node("QuestsPanel/Panel/ScrollContainer/VBoxContainer")
@onready var backButton: Button = get_node("QuestsPanel/Panel/BackButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func toggle():
	visible = not visible
	if visible:
		load_quests_panel()
		
func load_quests_panel():
	update_filter_buttons()
	
	var existingPanels = get_tree().get_nodes_in_group("QuestSlotPanel")
	for panel in existingPanels:
		panel.queue_free()
	
	var questSlotPanel = load("res://Prefabs/UI/Quests/QuestSlotPanel.tscn")
	for questTracker in PlayerResources.questInventory.quests:
		var instantiatedPanel: QuestSlotPanel = questSlotPanel.instantiate()
		instantiatedPanel.questTracker = questTracker
		instantiatedPanel.turnInName = turnInTargetName
		instantiatedPanel.questsMenu = self
		vboxViewport.add_child(instantiatedPanel)

func update_filter_buttons():
	inProgressButton.button_pressed = selectedFilter == QuestTracker.Status.IN_PROGRESS
	readyToTurnInButton.button_pressed = selectedFilter == QuestTracker.Status.READY_TO_TURN_IN_STEP
	completedButton.button_pressed = selectedFilter == QuestTracker.Status.COMPLETED
	notCompletedButton.button_pressed = selectedFilter == QuestTracker.Status.INCOMPLETE
	
	inProgressButton.disabled = lockFilters
	readyToTurnInButton.disabled = lockFilters
	completedButton.disabled = lockFilters
	notCompletedButton.disabled = lockFilters

func filter_by(type: QuestTracker.Status = QuestTracker.Status.ALL):
	selectedFilter = type
	load_quests_panel()

func turn_in(questTracker: QuestTracker):
	PlayerResources.questInventory.turn_in_cur_step(questTracker)
	# TODO show player rewards
	load_quests_panel()
	
func show_details(questTracker: QuestTracker):
	pass # TODO

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
