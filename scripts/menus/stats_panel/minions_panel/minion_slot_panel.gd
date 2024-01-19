extends Panel
class_name MinionSlotPanel

signal stats_clicked(combatant: Combatant)

@export var combatant: Combatant = null
@export var readOnly: bool = false

@onready var minionSprite: AnimatedSprite2D = get_node("SpriteControl/MinionSprite")
@onready var minionName: RichTextLabel = get_node("MinionName")
@onready var statPtIndicator: Control = get_node("StatPtIndicatorControl")
@onready var statsButton: Button = get_node("StatsButton")

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

func _on_stats_button_pressed():
	stats_clicked.emit(combatant)
