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
@onready var equipButton: Button = get_node("CenterButtons/HBoxContainer/EquipButton")
@onready var trashButton: Button = get_node("CenterButtons/HBoxContainer/TrashButton")
@onready var buyButton: Button = get_node("CenterButtons/HBoxContainer/BuyButton")
@onready var sellButton: Button = get_node("CenterButtons/HBoxContainer/SellButton")

# Called when the node enters the scene tree for the first time.
func _ready():
	load_inventory_slot_panel()

func load_inventory_slot_panel():
	if inventorySlot == null:
		return
	
	itemSprite.texture = inventorySlot.item.itemSprite
	itemName.text = inventorySlot.item.itemName
	itemType.text = Item.TypeToString(inventorySlot.item.itemType)
	itemCount.text = 'x' + String.num(inventorySlot.count)
	if inventorySlot.item.maxCount > 0:
		itemCount.append_text(' / ' + String.num(inventorySlot.item.maxCount))
	itemCost.text = String.num(inventorySlot.item.cost)	
	useButton.visible = not isShopItem
	useButton.disabled = not inventorySlot.item.usable
	equipButton.visible = not isShopItem and inventorySlot.item.equippable
	trashButton.visible = not isShopItem
	trashButton.disabled = not inventorySlot.item.consumable
	buyButton.visible = isShopItem and not isPlayerItem
	sellButton.visible = isShopItem and isPlayerItem
	
	
func _on_use_button_pressed():
	PlayerResources.inventory.use_item(inventorySlot.item, null) # TODO pick target

func _on_equip_button_pressed():
	PlayerResources.inventory.equip_item(inventorySlot)

func _on_trash_button_pressed():
	PlayerResources.inventory.trash_item(inventorySlot)

func _on_buy_button_pressed():
	inventoryMenu.buy_item(inventorySlot)
	
func _on_sell_button_pressed():
	inventoryMenu.sell_item(inventorySlot)

func _on_details_button_pressed():
	inventoryMenu.view_item_details(inventorySlot)
