extends Control
class_name OverworldTouchControls

signal pause_pressed
signal inventory_pressed
signal stats_pressed
signal quests_pressed
signal run_toggled

@export var runIcon: Texture2D = null
@export var walkIcon: Texture2D = null

@onready var inventoryButton: Button = get_node('HBoxContainer/InventoryButton')
@onready var questsButton = get_node('HBoxContainer/QuestsButton')
@onready var statsButton = get_node('HBoxContainer/StatsButton')
@onready var runToggleButton: Button = get_node('HBoxContainer/RunToggleButton')
@onready var pauseButton: Button = get_node('HBoxContainer/PauseButton')

@onready var touchVirtualJoystick: TouchVirtualJoystick = get_node('TouchVirtualJoystick')

@onready var virtualArrows: Control = get_node('VirtualArrows')

@onready var talkButton: Control = get_node('TalkControl')

var inCutscene: bool = false
var inDialogue: bool = false
var interactAvailable: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	set_all_visible()
	set_running(PlayerFinder.player.running)

func set_all_visible(isVisible: bool = true):
	var shouldShow: bool = isVisible and SettingsHandler.isMobile
	if not visible and shouldShow:
		touchVirtualJoystick.recheck_joystick_hold()
	visible = shouldShow

func set_running(isRunning: bool):
	runToggleButton.button_pressed = isRunning
	runToggleButton.icon = runIcon if isRunning else walkIcon

func set_in_cutscene(isInCutscene: bool):
	inCutscene = isInCutscene
	update_controls_visibility()

func set_in_dialogue(isInDialogue: bool):
	inDialogue = isInDialogue
	update_controls_visibility()

func set_interact_available(isInteractAvailable: bool):
	interactAvailable = isInteractAvailable
	update_controls_visibility()

func update_controls_visibility():
	inventoryButton.visible = not inCutscene
	questsButton.visible = not inCutscene
	statsButton.visible = not inCutscene
	runToggleButton.visible = not inCutscene
	# NOTE: only full visiblility hide on entire controls set should re-check the joystick hold
	# For example, moving between maps should re-check, but not tapping through to the end of dialogue or finishing a cutscene. Those should just release the joystick
	if not touchVirtualJoystick.visible and not inCutscene and not inDialogue:
		touchVirtualJoystick.release_joystick()
		#touchVirtualJoystick.recheck_joystick_hold()
	touchVirtualJoystick.visible = not inCutscene and not inDialogue
	#virtualArrows.visible = not inCutscene and not inDialogue
	talkButton.visible = not inCutscene and not inDialogue and interactAvailable

func _on_pause_button_pressed():
	pause_pressed.emit()

func _on_inventory_button_pressed():
	inventory_pressed.emit()

func _on_stats_button_pressed():
	stats_pressed.emit()

func _on_quests_button_pressed():
	quests_pressed.emit()

func _on_run_toggle_button_pressed():
	run_toggled.emit()

func _on_talk_button_released():
	# done on release input rather than defining action to take inside the TouchScreenButton node
	var interactEvent: InputEventAction = InputEventAction.new()
	interactEvent.action = 'game_interact'
	interactEvent.pressed = true
	Input.parse_input_event(interactEvent)
