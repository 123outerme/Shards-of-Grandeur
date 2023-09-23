extends Panel
class_name InventorySlotPanel

@export var inventorySlot: InventorySlot = null
@export var isShopItem: bool = false
@export var isPlayerItem: bool = true
@export var inventoryMenu: InventoryMenu

@onready var itemSprite: Sprite2D = get_node("ItemSprite")
@onready var itemName: RichTextLabel = get_node("CenterItemName/ItemName")
@onready var itemType: RichTextLabel = get_node("CenterItemType/ItemType")
@onready var itemCount: RichTextLabel = get_node("CenterItemCount/ItemCount")
@onready var itemCost: RichTextLabel = get_node("CenterItemCost/ItemCost")
@onready var useButton: Button = get_node("CenterButtons/HBoxContainer/UseButton")
@onready var trashButton: Button = get_node("CenterButtons/HBoxContainer/TrashButton")
@onready var buyButton: Button = get_node("CenterButtons/HBoxContainer/BuyButton")
@onready var sellButton: Button = get_node("CenterButtons/HBoxContainer/SellButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_inventory_slot_panel()

func load_inventory_slot_panel():
	if inventorySlot != null:
		itemSprite.texture = inventorySlot.item.itemSprite
		itemName.text = inventorySlot.item.itemName
		itemType.text = Item.TypeToString(inventorySlot.item.itemType)
		itemCount.text = 'x' + String.num(inventorySlot.count)
		if inventorySlot.item.maxCount > 0:
			itemCount.append_text(' / ' + String.num(inventorySlot.item.maxCount))
		itemCost.text = String.num(inventorySlot.item.cost)
	
	useButton.visible = not isShopItem
	trashButton.visible = not isShopItem
	buyButton.visible = isShopItem and not isPlayerItem
	sellButton.visible = isShopItem and isPlayerItem
	
func _on_use_button_pressed():
	inventoryMenu.use_item(inventorySlot)


func _on_trash_button_pressed():
	inventoryMenu.trash_item(inventorySlot)

func _on_buy_button_pressed():
	inventoryMenu.buy_item(inventorySlot)
	
func _on_sell_button_pressed():
	inventoryMenu.sell_item(inventorySlot)
