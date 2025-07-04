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
@onready var attunementDetails: Control = get_node('AttunementDetails')
@onready var friendshipBar: ProgressBar = get_node('AttunementDetails/FriendshipBar')
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
	
	if minion.friendship >= minion.maxFriendship and minion.fullyAttuned:
		shardItemSlot = null # if there is an item slot, this will clear it
	
	minionSprite.sprite_frames = minion.get_sprite_frames()
	var combatantSprite: CombatantSprite = minion.get_sprite_obj()
	minionSprite.offset = (combatantSprite.maxSize / 2) - combatantSprite.idleCanvasCenterPosition
	minionSprite.flip_h = combatantSprite.spriteFacesRight
	if combatantSprite.spriteFacesRight: # if flipping, invert the X offset
		minionSprite.offset.x *= -1
	
	if minion.get_idle_size().x <= 16 and minion.get_idle_size().y <= 16:
		minionSprite.scale = Vector2(3, 3)
	elif minion.get_idle_size().x < 48 and minion.get_idle_size().y < 48:
		minionSprite.scale = Vector2(2, 2)
	else:
		minionSprite.scale = Vector2(2, 2)
		
	minionSprite.play('battle_idle')
	minionName.text = minion.disp_name()
	
	shardDetails.visible = shardItemSlot != null
	attunementDetails.visible = shardDetails.visible
	unlockedSpriteControl.visible = not shardDetails.visible
	if shardDetails.visible:
		shardCount.text = 'x' + String.num_int64(shardItemSlot.count)
		shardSprite.texture = shardItemSlot.item.itemSprite
		friendshipBar.max_value = minion.maxFriendship
		friendshipBar.value = minion.friendship
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
