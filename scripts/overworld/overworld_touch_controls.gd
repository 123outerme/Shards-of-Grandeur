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

@onready var virtualArrows: Control = get_node('VirtualArrows')

# Called when the node enters the scene tree for the first time.
func _ready():
	set_running(PlayerFinder.player.running)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_running(isRunning: bool):
	runToggleButton.button_pressed = isRunning
	runToggleButton.icon = runIcon if isRunning else walkIcon

func set_in_cutscene(inCutscene: bool):
	virtualArrows.visible = not inCutscene
	inventoryButton.visible = not inCutscene
	questsButton.visible = not inCutscene
	statsButton.visible = not inCutscene
	runToggleButton.visible = not inCutscene

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

