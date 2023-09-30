extends Panel
class_name InventorySlotPanel

@export var inventorySlot: InventorySlot = null
@export var isShopItem: bool = false
@export var isPlayerItem: bool = true
@export var isEquipped: bool = false
@export var inventoryMenu: InventoryMenu

@onready var itemSprite: Sprite2D = get_node("ItemSprite")
@onready var itemName: RichTextLabel = get_node("CenterItemName/ItemName")
@onready var itemType: RichTextLabel = get_node("CenterItemType/ItemType")
@onready var itemCount: RichTextLabel = get_node("CenterItemCount/ItemCount")
@onready var itemCost: RichTextLabel = get_node("CenterItemCost/ItemCost")
@onready var useButton: Button = get_node("CenterButtons/HBoxContainer/UseButton")
@onready var equipButton: Button = get_node("CenterButtons/HBoxContainer/EquipButton")
@onready var unequipButton: Button = get_node("CenterButtons/HBoxContainer/UnequipButton")
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
	itemCount.text = 'x' + TextUtils.num_to_comma_string(inventorySlot.count)
	if inventorySlot.item.maxCount > 1:
		itemCount.append_text(' / ' + TextUtils.num_to_comma_string(inventorySlot.item.maxCount))
	itemCost.text = TextUtils.num_to_comma_string(inventorySlot.item.cost)	
	useButton.visible = not isShopItem and not inventorySlot.item.equippable # hide if it's a shop item or if it's equippable
	useButton.disabled = not inventorySlot.item.usable
	equipButton.visible = not isShopItem and inventorySlot.item.equippable and not isEquipped
	unequipButton.visible = not isShopItem and isEquipped
	trashButton.visible = not isShopItem
	trashButton.disabled = not (inventorySlot.item.consumable or inventorySlot.item.equippable) or isEquipped
	buyButton.visible = isShopItem and not isPlayerItem
	buyButton.disabled = inventorySlot.item.cost > PlayerResources.playerInfo.gold
	sellButton.visible = isShopItem and isPlayerItem and not isEquipped
	sellButton.disabled = isShopItem and not isPlayerItem and inventorySlot.count >= inventorySlot.item.maxCount	
	
func _on_use_button_pressed():
	PlayerResources.inventory.use_item(inventorySlot.item, null) # TODO pick target
	inventoryMenu.load_inventory_panel() # rebuild the whole menu - item slot might have been all used up

func _on_equip_button_pressed():
	PlayerResources.inventory.equip_item(inventorySlot)
	inventoryMenu.load_inventory_panel() # rebuild the whole menu - another item may have been unequipped

func _on_unequip_button_pressed():
	PlayerResources.inventory.equip_item(inventorySlot, false)
	isEquipped = false
	inventoryMenu.load_inventory_panel() # rebuild the whole menu - item order may have changed
	
func _on_trash_button_pressed():
	PlayerResources.inventory.trash_item(inventorySlot)
	inventoryMenu.load_inventory_panel() # rebuild the whole menu - item slot may be all gone

func _on_buy_button_pressed():
	inventoryMenu.buy_item(inventorySlot)
	inventoryMenu.load_inventory_panel() # rebuild the whole menu - item slot may be all gone
	
func _on_sell_button_pressed():
	inventoryMenu.sell_item(inventorySlot)
	inventoryMenu.load_inventory_panel() # rebuild the whole menu - item slot may be all gone

func _on_details_button_pressed():
	inventoryMenu.view_item_details(inventorySlot)
