extends Panel
class_name MinionSlotPanel

signal stats_clicked(combatant: Combatant)
signal reorder_clicked(combatant: Combatant)
signal panel_ready

@export var combatant: Combatant = null
@export var readOnly: bool = false
@export var showReorderButton: bool = false
@export var reorderButtonIsTarget: bool = false
@export var reorderButtonIsCancel: bool = false

var readyCallback: Callable

@onready var minionSprite: AnimatedSprite2D = get_node("SpriteControl/MinionSprite")
@onready var minionName: RichTextLabel = get_node("MinionName")
@onready var statPtIndicator: Control = get_node("HBoxContainer/VBoxContainer/StatPtIndicatorControl")
@onready var reorderButton: Button = get_node('HBoxContainer/ReorderButton')
@onready var statsButton: Button = get_node("HBoxContainer/StatsButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_minion_slot_panel()
	
func load_minion_slot_panel():
	if combatant == null:
		visible = false
		return
	
	minionSprite.sprite_frames = combatant.spriteFrames
	if combatant.spriteFrames == null:
		minionSprite.sprite_frames = load('res://graphics/animations/a_player.tres') # TEMP
	minionSprite.play('walk')
	minionName.text = combatant.disp_name()
	statPtIndicator.visible = not readOnly and combatant.stats.statPts > 0
	reorderButton.visible = showReorderButton
	if reorderButtonIsTarget:
		reorderButton.text = 'Move Here'
	elif reorderButtonIsCancel:
		reorderButton.text = 'Cancel'
	else:
		reorderButton.text = 'Reorder'
	panel_ready.emit()

func _on_stats_button_pressed():
	stats_clicked.emit(combatant)

func _on_reorder_button_pressed():
	reorder_clicked.emit(combatant)
