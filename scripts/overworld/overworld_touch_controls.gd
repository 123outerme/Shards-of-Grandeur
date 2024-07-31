extends Control
class_name OverworldTouchControls

signal pause_pressed
signal inventory_pressed
signal stats_pressed
signal quests_pressed
signal run_toggled

@export var runIcon: Texture2D = null
@export var walkIcon: Texture2D = null
@export var buttonSfx: AudioStream = null

@onready var inventoryButtonPanel: Panel = get_node('HBoxContainer/InventoryButtonPanel')
@onready var questsButtonPanel = get_node('HBoxContainer/QuestsButtonPanel')
@onready var statsButtonPanel = get_node('HBoxContainer/StatsButtonPanel')
@onready var runToggleButtonPanel: Panel = get_node('HBoxContainer/RunToggleButtonPanel')
@onready var runToggleButton: TouchScreenButton = get_node('HBoxContainer/RunToggleButtonPanel/RunToggleButton')
@onready var pauseButtonPanel: Panel = get_node('HBoxContainer/PauseButtonPanel')

@onready var touchVirtualJoystick: TouchVirtualJoystick = get_node('TouchVirtualJoystick')

@onready var talkButton: Control = get_node('TalkControl')

var inCutscene: bool = false
var inDialogue: bool = false
var interactAvailable: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# defer a frame because the player and PlayerFinder will _ready() AFTER this control
	await get_tree().process_frame
	set_running(PlayerFinder.player.running)
	set_in_cutscene(PlayerFinder.player.inCutscene)
	set_in_dialogue(PlayerFinder.player.textBox.visible)
	PlayerFinder.player.update_interact_touch_ui()

func set_all_visible(isVisible: bool = true):
	var shouldShow: bool = isVisible and SettingsHandler.isMobile
	if not visible and shouldShow and touchVirtualJoystick.visible:
		touchVirtualJoystick.recheck_joystick_hold()
	visible = shouldShow

func set_running(isRunning: bool):
	runToggleButton.texture_normal = runIcon if isRunning else walkIcon

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
	inventoryButtonPanel.visible = not inCutscene
	questsButtonPanel.visible = not inCutscene
	statsButtonPanel.visible = not inCutscene
	runToggleButtonPanel.visible = not inCutscene
	# NOTE: only full visiblility hide on entire controls set should re-check the joystick hold
	# For example, moving between maps should re-check, but not tapping through to the end of dialogue or finishing a cutscene. Those should just release the joystick
	if not touchVirtualJoystick.visible and not inCutscene and not inDialogue:
		touchVirtualJoystick.release_joystick()
		#touchVirtualJoystick.recheck_joystick_hold()
	touchVirtualJoystick.visible = not inCutscene and not inDialogue
	talkButton.visible = not inCutscene and not inDialogue and interactAvailable

func _on_pause_button_released():
	pause_pressed.emit()
	SceneLoader.audioHandler.play_sfx(buttonSfx)

func _on_inventory_button_released():
	inventory_pressed.emit()
	SceneLoader.audioHandler.play_sfx(buttonSfx)

func _on_stats_button_released():
	stats_pressed.emit()
	SceneLoader.audioHandler.play_sfx(buttonSfx)

func _on_quests_button_released():
	quests_pressed.emit()
	SceneLoader.audioHandler.play_sfx(buttonSfx)

func _on_run_toggle_button_pressed():
	run_toggled.emit()
	SceneLoader.audioHandler.play_sfx(buttonSfx)

func _on_talk_button_released():
	# done on release input rather than defining action to take inside the TouchScreenButton node
	var interactEvent: InputEventAction = InputEventAction.new()
	interactEvent.action = 'game_interact'
	interactEvent.pressed = true
	Input.parse_input_event(interactEvent)
	SceneLoader.audioHandler.play_sfx(buttonSfx)
