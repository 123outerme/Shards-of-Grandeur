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

func load_reward_panel() -> void:
	if reward != null:
		goldGroup.visible = true
		expLabel.visible = true
		noRewardsLabel.visible = false
		expLabel.text = '[right]' + TextUtils.num_to_comma_string(reward.experience) + ' Exp.[/right]'
		goldLabel.text = TextUtils.num_to_comma_string(reward.gold)
		if reward.item != null:
			itemGroup.visible = true
			itemSpriteBtn.texture_normal = reward.item.itemSprite
			itemName.text = reward.item.itemName + ' x' + TextUtils.num_to_comma_string(reward.itemCount)
		else:
			itemGroup.visible = false
	else:
		noRewardsLabel.visible = true
		expLabel.visible = false
		goldGroup.visible = false
		itemGroup.visible = false
	visible = true


func _on_item_sprite_button_pressed() -> void:
	show_item_details.emit(reward.item)
