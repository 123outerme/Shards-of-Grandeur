extends Panel
class_name EquipCombatantPanel

@export var combatant: Combatant = null
@export var item: Item = null

var parentPanel: EquipPanel = null

@onready var animatedCombatantSprite: AnimatedSprite2D = get_node('SpriteControl/CombatantSprite')
@onready var combatantName: RichTextLabel = get_node('CenterCombatantName/CombatantName')
@onready var itemSprite: Sprite2D = get_node('ItemSpriteControl/ItemSprite')
@onready var statsButton: Button = get_node('CenterButtons/HBoxContainer/StatsButton')
@onready var equipButton: Button = get_node('CenterButtons/HBoxContainer/EquipButton')
@onready var unequipButton: Button = get_node('CenterButtons/HBoxContainer/UnequipButton')

# Called when the node enters the scene tree for the first time.
func _ready():
	load_equip_combatant_panel()

func initial_focus():
	if equipButton.visible:
		equipButton.grab_focus()
	else:
		unequipButton.grab_focus()

func focus_stats_button():
	statsButton.grab_focus()

func load_equip_combatant_panel():
	if combatant == null or parentPanel == null:
		return
	
	equipButton.visible = not combatant.stats.is_item_equipped(item)
	unequipButton.visible = not equipButton.visible
	
	combatantName.text = combatant.disp_name()
	
	animatedCombatantSprite.sprite_frames = combatant.spriteFrames
	animatedCombatantSprite.play('walk')
	
	itemSprite.texture = item.itemSprite
	itemSprite.visible = unequipButton.visible

func _on_stats_button_pressed():
	parentPanel.stats_pressed(combatant)

func _on_equip_button_pressed():
	parentPanel.equip_pressed(combatant)

func _on_unequip_button_pressed():
	parentPanel.unequip_pressed(combatant)
