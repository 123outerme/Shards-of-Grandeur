extends Panel
class_name SummonMinionListPanel

@export var minion: Combatant = null
@export var shardItemSlot: InventorySlot = null
@export var parentPanel: SummonMinionPanel = null

@onready var minionSprite: AnimatedSprite2D = get_node('SpriteControl/MinionSprite')
@onready var minionName: RichTextLabel = get_node('CenterMinionName/MinionName')
@onready var shardDetails: Control = get_node('ShardDetails')
@onready var shardCount: RichTextLabel = get_node('ShardDetails/ShardCount')
@onready var shardSprite: Sprite2D = get_node('ShardDetails/ShardSpriteControl/ShardSprite')
@onready var statsButton: Button = get_node('CenterButtons/HBoxContainer/StatsButton')
@onready var summonButton: Button = get_node('CenterButtons/HBoxContainer/SummonButton')

# Called when the node enters the scene tree for the first time.
func _ready():
	load_summon_minion_list_panel()

func load_summon_minion_list_panel():
	if minion == null:
		return
		
	minionSprite.sprite_frames = minion.spriteFrames
	
	if minion.maxSize.x <= 16 and minion.maxSize.y <= 16:
		minionSprite.scale = Vector2(3, 3)
	elif minion.maxSize.x < 48 and minion.maxSize.y < 48:
		minionSprite.scale = Vector2(2.5, 2.5)
	else:
		minionSprite.scale = Vector2(2, 2)
		
	minionSprite.play('walk')
	minionName.text = minion.disp_name()
	
	shardDetails.visible = shardItemSlot != null
	if shardDetails.visible:
		shardCount.text = 'x' + String.num(shardItemSlot.count)
		shardSprite.texture = shardItemSlot.item.itemSprite
	
func focus_summon_button():
	summonButton.grab_focus()

func focus_stats_button():
	statsButton.grab_focus()

func _on_summon_button_pressed():
	parentPanel.summon_minion(minion, shardItemSlot)

func _on_stats_button_pressed():
	parentPanel.show_minion_stats(minion)
