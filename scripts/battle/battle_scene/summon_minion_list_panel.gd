extends Panel
class_name SummonMinionListPanel

@export var minion: Combatant = null
@export var shardItemSlot: InventorySlot = null
@export var parentPanel: SummonMinionPanel = null

@onready var minionSprite: AnimatedSprite2D = get_node('SpriteControl/MinionSprite')
@onready var minionName: RichTextLabel = get_node('CenterMinionName/MinionName')
@onready var shardDetails: Control = get_node('SummonDetails/ShardDetails')
@onready var shardCount: RichTextLabel = get_node('SummonDetails/ShardDetails/ShardCount')
@onready var shardSprite: Sprite2D = get_node('SummonDetails/ShardDetails/ShardSpriteControl/ShardSprite')
@onready var unlockedSpriteControl: Control = get_node('SummonDetails/UnlockedSpriteControl')
@onready var unlockedSprite: AnimatedSprite2D = get_node('SummonDetails/UnlockedSpriteControl/UnlockedSprite')
@onready var statsButton: Button = get_node('CenterButtons/HBoxContainer/StatsButton')
@onready var summonButton: Button = get_node('CenterButtons/HBoxContainer/SummonButton')

# Called when the node enters the scene tree for the first time.
func _ready():
	load_summon_minion_list_panel()

func load_summon_minion_list_panel():
	if minion == null:
		return
	
	if minion.friendship >= minion.maxFriendship:
		shardItemSlot = null # if there is an item slot, this will clear it
	
	minionSprite.sprite_frames = minion.get_sprite_frames()
	
	if minion.maxSize.x <= 16 and minion.maxSize.y <= 16:
		minionSprite.scale = Vector2(3, 3)
	elif minion.maxSize.x < 48 and minion.maxSize.y < 48:
		minionSprite.scale = Vector2(2, 2)
	else:
		minionSprite.scale = Vector2(2, 2)
		
	minionSprite.play('walk')
	minionName.text = minion.disp_name()
	
	shardDetails.visible = shardItemSlot != null
	unlockedSpriteControl.visible = not shardDetails.visible
	if shardDetails.visible:
		shardCount.text = 'x' + String.num(shardItemSlot.count)
		shardSprite.texture = shardItemSlot.item.itemSprite
	else:
		unlockedSprite.play('default')
	
func focus_summon_button():
	summonButton.grab_focus()

func focus_stats_button():
	statsButton.grab_focus()

func _on_summon_button_pressed():
	parentPanel.summon_minion(minion, shardItemSlot)

func _on_stats_button_pressed():
	parentPanel.show_minion_stats(minion)
