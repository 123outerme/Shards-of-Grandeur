extends Control
class_name ItemDetailsPanel

@export var item: Item
@export var count: int = 0

@onready var itemName: RichTextLabel = get_node("Panel/ItemName")
@onready var itemSprite: Sprite2D = get_node("Panel/ItemSprite")
@onready var itemType: RichTextLabel = get_node("Panel/ItemType")
@onready var itemEffect: RichTextLabel = get_node("Panel/ItemEffect")
@onready var itemDescription: RichTextLabel = get_node("Panel/ItemDescription")
@onready var itemCost: RichTextLabel = get_node("Panel/ItemCostGroup/ItemCost")
@onready var itemCount: RichTextLabel = get_node("Panel/ItemCount")
@onready var backButton: Button = get_node("Panel/BackButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_item_details()

func load_item_details():
	if item == null:
		return
	
	itemName.text = '[center]' + item.itemName + '[/center]'
	itemSprite.texture = item.itemSprite
	itemType.text = '[center]' + Item.TypeToString(item.itemType) + '[/center]'
	itemEffect.text = '[center]' + item.get_effect_text() + '[/center]'
	itemDescription.text = item.itemDescription
	itemCost.text = String.num(item.cost)
	if count > 0:
		itemCount.visible = true
		itemCount.text = 'x' + String.num(count) + ' / ' + String.num(item.maxCount)
	else:
		itemCount.visible = false
	backButton.grab_focus()

func _on_back_button_pressed():
	visible = false
