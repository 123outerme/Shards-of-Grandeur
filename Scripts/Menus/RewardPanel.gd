extends Panel
class_name RewardPanel

@export var reward: Reward = null
var itemDetailsPanel: ItemDetailsPanel = null

@onready var expLabel: RichTextLabel = get_node("Exp")
@onready var goldLabel: RichTextLabel = get_node("GoldGroup/Gold")
@onready var itemGroup: Control = get_node("ItemGroup")
@onready var itemSpriteBtn: TextureButton = get_node("ItemGroup/ItemSpriteButton")
@onready var itemName: RichTextLabel = get_node("ItemGroup/ItemName")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_reward_panel(itemDetailsPanel: ItemDetailsPanel):
	if reward != null:
		visible = true
		expLabel.text = '[center]' + TextUtils.NumToCommaString(reward.experience) + ' Exp.[/center]'
		goldLabel.text = TextUtils.NumToCommaString(reward.gold)
		if reward.item != null:
			itemGroup.visible = true
			itemSpriteBtn.texture_normal = reward.item.itemSprite
			itemName.text = reward.item.itemName
		else:
			itemGroup.visible = false
		itemDetailsPanel.item = reward.item
	else:
		visible = false
