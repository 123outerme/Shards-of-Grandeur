extends Panel
class_name QuestSlotPanel

var questTracker: QuestTracker = null
var turnInName: String = ''
var questsMenu: QuestsMenu

var loaded: bool = false

@onready var pinButton: TextureButton = get_node("PinButton")
@onready var questName: RichTextLabel = get_node("CenterQuestName/QuestName")
@onready var stepName: RichTextLabel = get_node("CenterQuestName/QuestStepName")
@onready var progress: RichTextLabel = get_node("CenterProgress/QuestProgress")
@onready var mainQuestSprite: Control = get_node("CenterButtons/HBoxContainer/MainQuestSpriteControl")
@onready var turnInButton: Button = get_node("CenterButtons/HBoxContainer/TurnInButton")
@onready var detailsButton: Button = get_node("CenterButtons/HBoxContainer/DetailsButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_quest_slot_panel()

func load_quest_slot_panel():
	if questTracker == null:
		return
	
	loaded = false
	pinButton.button_pressed = questTracker.pinned
	var curStep: QuestStep = questTracker.get_current_step()
	questName.text = questTracker.quest.questName
	stepName.text = curStep.name
	progress.text = questTracker.get_step_status_str(curStep)
	mainQuestSprite.visible = questTracker.quest.isMainQuest
	turnInButton.visible = turnInName in curStep.turnInNames and questTracker.get_current_status() == QuestTracker.Status.READY_TO_TURN_IN_STEP
	if not turnInButton.visible:
		detailsButton.focus_neighbor_left = detailsButton.get_path_to(pinButton)
		pinButton.focus_neighbor_right = pinButton.get_path_to(detailsButton)
	loaded = true

func _on_pin_button_toggled(button_pressed: bool):
	questTracker.pinned = button_pressed
	if loaded:
		questsMenu.pin_button_pressed(questTracker)

func _on_turn_in_button_pressed():
	questsMenu.turn_in(questTracker)

func _on_details_button_pressed():
	questsMenu.show_details(questTracker)
