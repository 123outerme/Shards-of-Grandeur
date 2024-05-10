extends Panel
class_name RewardPanel

signal show_item_details(item)

@export var reward: Reward = null

@onready var expLabel: RichTextLabel = get_node("Exp")
@onready var goldGroup: Control = get_node('GoldGroup')
@onready var goldLabel: RichTextLabel = get_node("GoldGroup/Gold")
@onready var itemGroup: Control = get_node("ItemGroup")
@onready var itemSpriteBtn: TextureButton = get_node("ItemGroup/ItemSpriteButton")
@onready var itemName: RichTextLabel = get_node("ItemGroup/ItemName")
@onready var noRewardsLabel: RichTextLabel = get_node('NoRewardsLabel')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_reward_panel():
	if reward != null:
		visible = true
		expLabel.text = '[center]' + TextUtils.num_to_comma_string(reward.experience) + ' Exp.[/center]'
		goldGroup.visible = true
		goldLabel.text = TextUtils.num_to_comma_string(reward.gold)
		if reward.item != null:
			itemGroup.visible = true
			itemSpriteBtn.texture_normal = reward.item.itemSprite
			itemName.text = reward.item.itemName
		else:
			itemGroup.visible = false
		noRewardsLabel.visible = false
	else:
		noRewardsLabel.visible = true
		expLabel.visible = false
		goldGroup.visible = false
		itemGroup.visible = false
		visible = true


func _on_item_sprite_button_pressed():
	show_item_details.emit(reward.item)
