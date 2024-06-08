extends Panel
class_name InventorySlotPanel

@export var inventorySlot: InventorySlot = null
@export var isShopItem: bool = false
@export var isPlayerItem: bool = true
@export var isEquipped: bool = false
@export var inBattle: bool = false
@export var summoning: bool = false
@export var inventoryMenu: InventoryMenu
@export var queuedForBattleUse: bool = false
@export var equipContextStats: Stats = null
@export var canOtherPartyHold: bool = false

@onready var itemSprite: Sprite2D = get_node("ItemSprite")
@onready var itemName: RichTextLabel = get_node("CenterItemName/ItemName")
@onready var itemType: RichTextLabel = get_node("CenterItemType/ItemType")
@onready var itemCount: RichTextLabel = get_node("CenterItemCount/ItemCount")
@onready var equippedTo: RichTextLabel = get_node("CenterEqiuppedTo/EquippedTo")
@onready var centerItemCost: VBoxContainer = get_node("CenterItemCost")
@onready var itemCost: RichTextLabel = get_node("CenterItemCost/ItemCost")
@onready var useButton: Button = get_node("CenterButtons/HBoxContainer/UseButton")
@onready var equipButton: Button = get_node("CenterButtons/HBoxContainer/EquipButton")
@onready var trashButton: Button = get_node("CenterButtons/HBoxContainer/TrashButton")
@onready var buyButton: Button = get_node("CenterButtons/HBoxContainer/BuyButton")
@onready var sellButton: Button = get_node("CenterButtons/HBoxContainer/SellButton")
@onready var detailsButton: Button = get_node("CenterButtons/HBoxContainer/DetailsButton")

# shows the Inventory panel where the tutorial arrow should go
# (but not nested in here, so it isn't clipped by the scroll container)
@onready var tutorialArrowTargetControl: Control = get_node('CenterButtons/HBoxContainer/UseButton/TutorialArrowTargetControl')

# Called when the node enters the scene tree for the first time.
func _ready():
	load_inventory_slot_panel()

func load_inventory_slot_panel():
	if inventorySlot == null:
		return
	
	var displayCount: int = inventorySlot.count
	if queuedForBattleUse:
		displayCount -= 1
	itemSprite.texture = inventorySlot.item.itemSprite
	itemName.text = inventorySlot.item.itemName
	itemType.text = Item.type_to_string(inventorySlot.item.itemType)
	if inventorySlot.count > 0:
		itemCount.text = 'x' + TextUtils.num_to_comma_string(displayCount)
		if inventorySlot.item.maxCount > 1:
			itemCount.text += ' / ' + TextUtils.num_to_comma_string(inventorySlot.item.maxCount)
	else:
		itemCount.text = ''
	
	if inventorySlot.item.cost >= 0:
		itemCost.text = TextUtils.num_to_comma_string(inventorySlot.item.cost)
		centerItemCost.visible = true
	else:
		centerItemCost.visible = false
	
	useButton.visible = not isShopItem and not inventorySlot.item.equippable # hide if it's a shop item or if it's equippable
	useButton.disabled = not inventorySlot.item.usable or \
			((not inventorySlot.item.battleUsable or displayCount <= 0) and inBattle) or \
			not inventorySlot.item.can_be_used_now()
	
	equipButton.visible = not isShopItem and inventorySlot.item.equippable
	equipButton.disabled = inBattle
	
	equippedTo.text = ''
	if inventorySlot.item.equippable:
		var combatant: Combatant = null
		if PlayerResources.playerInfo.combatant.stats.is_item_equipped(inventorySlot.item):
			combatant = PlayerResources.playerInfo.combatant
		var minionName = PlayerResources.minions.which_minion_equipped(inventorySlot.item)
		if minionName != '':
			combatant = PlayerResources.minions.get_minion(minionName)
		if combatant != null:
			equippedTo.text = '[right]Equipped to:\n' + combatant.disp_name() + '[/right]'
	
	trashButton.visible = not isShopItem
	trashButton.disabled = not (inventorySlot.item.consumable or inventorySlot.item.equippable) or isEquipped
	
	buyButton.visible = isShopItem and not isPlayerItem
	buyButton.disabled = inventorySlot.item.cost > PlayerResources.playerInfo.gold or not canOtherPartyHold
	
	sellButton.visible = isShopItem and isPlayerItem
	sellButton.disabled = isEquipped or not canOtherPartyHold or inventorySlot.item.cost < 0

func get_leftmost_button() -> Button:
	var buttonArr: Array[Button] = [
		useButton,
		equipButton,
		trashButton,
		buyButton,
		sellButton,
		detailsButton
	]
	for idx in range(len(buttonArr)):
		if buttonArr[idx].visible:
			return buttonArr[idx]
	return null

func connect_button_focus_to(previousPanel: InventorySlotPanel):
	if previousPanel == null:
		return
	
	var firstButton: Button = useButton
	var previousFirstButton: Button = previousPanel.useButton
	if equipButton.visible:
		firstButton = equipButton
	if previousPanel.equipButton.visible:
		previousFirstButton = previousPanel.equipButton
	
	firstButton.focus_neighbor_top = firstButton.get_path_to(previousFirstButton)
	trashButton.focus_neighbor_top = trashButton.get_path_to(previousPanel.trashButton)
	buyButton.focus_neighbor_top = buyButton.get_path_to(previousPanel.buyButton)
	sellButton.focus_neighbor_top = sellButton.get_path_to(previousPanel.sellButton)
	detailsButton.focus_neighbor_top = detailsButton.get_path_to(previousPanel.detailsButton)
	
	previousFirstButton.focus_neighbor_bottom = previousFirstButton.get_path_to(firstButton)
	previousPanel.trashButton.focus_neighbor_bottom = previousPanel.trashButton.get_path_to(trashButton)
	previousPanel.buyButton.focus_neighbor_bottom = previousPanel.buyButton.get_path_to(buyButton)
	previousPanel.sellButton.focus_neighbor_bottom = previousPanel.sellButton.get_path_to(sellButton)
	previousPanel.detailsButton.focus_neighbor_bottom = previousPanel.detailsButton.get_path_to(detailsButton)

func _on_use_button_pressed():
	inventoryMenu.item_used.emit(inventorySlot)

func _on_equip_button_pressed():
	if equipContextStats != null:
		PlayerResources.inventory.equip_item(inventorySlot, true, equipContextStats)
	inventoryMenu.equip_pressed(inventorySlot, equipContextStats != null) # rebuild the whole menu - another item may have been unequipped

func _on_trash_button_pressed():
	inventoryMenu.trash_pressed(inventorySlot) # rebuild the whole menu - item slot may be all gone

func _on_buy_button_pressed():
	inventoryMenu.buy_item(inventorySlot)
	
func _on_sell_button_pressed():
	inventoryMenu.sell_item(inventorySlot)

func _on_details_button_pressed():
	inventoryMenu.view_item_details(inventorySlot)
