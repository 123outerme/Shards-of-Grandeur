extends Panel
class_name MinionSlotPanel

signal stats_clicked(combatant: Combatant)

@export var combatant: Combatant = null
@export var readOnly: bool = false

@onready var minionSprite: Sprite2D = get_node("SpriteControl/MinionSprite")
@onready var minionName: RichTextLabel = get_node("MinionName")
@onready var statsButton: Button = get_node("StatsButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_minion_slot_panel()
	
func load_minion_slot_panel():
	if combatant == null:
		visible = false
		return
	
	minionSprite.texture = combatant.sprite
	minionName.text = combatant.disp_name()
	statsButton.disabled = readOnly

func _on_stats_button_pressed():
	stats_clicked.emit(combatant)
