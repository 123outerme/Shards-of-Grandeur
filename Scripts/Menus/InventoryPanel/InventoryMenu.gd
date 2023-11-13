extends Node2D
class_name InventoryMenu

signal item_used(slot: InventorySlot)
signal back_pressed

@export_category("InventoryPanel - Filters")
@export var selectedFilter: Item.Type = Item.Type.ALL
@export var inBattle: bool = false
@export var summoning: bool = false
@export var lockFilters: bool = false

@export_category("InventoryPanel - Shops")
@export var inShop: bool = false
@export var showPlayerInventory = false
var shopInventory: Inventory = null

@export_category("InventoryPanel - Item Use Behavior")
@export var slotQueuedForBattleUse: InventorySlot = null
@export var showItemUsePanel: bool = false
@export var equipContextStats: Stats = null

@onready var vboxViewport = get_node("InventoryPanel/Panel/ScrollContainer/VBoxContainer")
@onready var inventoryTitle: RichTextLabel = get_node("InventoryPanel/Panel/InventoryTitle")
@onready var goldCount: RichTextLabel = get_node("InventoryPanel/Panel/GoldCountGroup/GoldCount")
@onready var toggleShopButton: Button = get_node("InventoryPanel/Panel/ToggleShopInventoryButton")

@onready var healingFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/HealingButton")
@onready var shardFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/ShardsButton")
@onready var weaponFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/WeaponsButton")
@onready var armorFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/ArmorButton")
@onready var keyItemFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/KeyItemsButton")
@onready var backButton: Button = get_node("InventoryPanel/Panel/BackButton")
@onready var itemDetailsPanel: ItemDetailsPanel = get_node("ItemDetailsPanel")
@onready var itemUsePanel: ItemUsePanel = get_node("ItemUsePanel")
@onready var shardLearnPanel: ShardLearnPanel = get_node("ShardLearnPanel")

var currentInventory: Inventory = null
var otherInventory: Inventory = null # player inventory if looking at NPC shop; NPC inventory if looking at player inventory inside NPC shop

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func toggle():
	visible = not visible
	if visible:
		get_display_inventory()
		check_filters()
		load_inventory_panel()
		initial_focus.call_deferred()
	else:
		itemDetailsPanel.visible = false
		itemUsePanel.visible = false
		if shardLearnPanel.visible:
			shardLearnPanel.credit_back_shard()
		shardLearnPanel.visible = false
		backButton.disabled = false
		if equipContextStats != null:
			lockFilters = false
			selectedFilter = Item.Type.ALL
		equipContextStats = null
		back_pressed.emit()

func initial_focus():
	if not healingFilterBtn.disabled:
		healingFilterBtn.grab_focus()
		return
		
	if not shardFilterBtn.disabled:
		shardFilterBtn.grab_focus()
		return
		
	if not weaponFilterBtn.disabled:
		weaponFilterBtn.grab_focus()
		return
		
	if not armorFilterBtn.disabled:
		armorFilterBtn.grab_focus()
		return
		
	if not keyItemFilterBtn.disabled:
		keyItemFilterBtn.grab_focus()
		return
	
	backButton.grab_focus()

func get_display_inventory():
	currentInventory = PlayerResources.inventory
	otherInventory = null
	if inShop:
		if not showPlayerInventory:
			currentInventory = shopInventory
			otherInventory = PlayerResources.inventory
		else:
			otherInventory = shopInventory

func load_inventory_panel():
	get_display_inventory()
	update_toggle_inv_button()
	update_filter_buttons()
	# lock all filters so that they can be unlocked as the inventory slots get created
	healingFilterBtn.disabled = true
	shardFilterBtn.disabled = true
	weaponFilterBtn.disabled = true
	armorFilterBtn.disabled = true
	keyItemFilterBtn.disabled = true
	
	for panel in get_tree().get_nodes_in_group("InventorySlotPanel"):
		panel.queue_free()
	
	inventoryTitle.text = '[center]Inventory[/center]'
	goldCount.text = TextUtils.num_to_comma_string(PlayerResources.playerInfo.gold)
	if inShop:
		if not showPlayerInventory:
			inventoryTitle.text = '[center]Shop Inventory[/center]'
		else:
			inventoryTitle.text = '[center]Your Inventory[/center]'
	
	var setFocus: bool = false
	var invSlotPanel = load("res://Prefabs/UI/Inventory/InventorySlotPanel.tscn")
	for slot in currentInventory.get_sorted_slots():
		if selectedFilter == Item.Type.ALL or selectedFilter == slot.item.itemType:
			var instantiatedPanel: InventorySlotPanel = invSlotPanel.instantiate()
			instantiatedPanel.isShopItem = inShop
			instantiatedPanel.isPlayerItem = showPlayerInventory or not inShop
			instantiatedPanel.isEquipped = currentInventory.is_equipped(slot.item) or (instantiatedPanel.isPlayerItem and PlayerResources.minions.which_minion_equipped(slot.item) != '')
			instantiatedPanel.inBattle = inBattle
			instantiatedPanel.summoning = summoning
			instantiatedPanel.inventoryMenu = self
			instantiatedPanel.inventorySlot = slot
			instantiatedPanel.queuedForBattleUse = slotQueuedForBattleUse == slot
			if otherInventory != null:
				instantiatedPanel.canOtherPartyHold = not otherInventory.is_slot_for_item_full(slot.item)
			instantiatedPanel.equipContextStats = equipContextStats
			vboxViewport.add_child(instantiatedPanel)
			# unlock filter button for filter of item's type
		if slot.item.itemType == Item.Type.HEALING:
			healingFilterBtn.disabled = lockFilters and selectedFilter != Item.Type.HEALING
		if slot.item.itemType == Item.Type.SHARD:
			shardFilterBtn.disabled = lockFilters and selectedFilter != Item.Type.SHARD
		if slot.item.itemType == Item.Type.WEAPON:
			weaponFilterBtn.disabled = lockFilters and selectedFilter != Item.Type.WEAPON
		if slot.item.itemType == Item.Type.ARMOR:
			armorFilterBtn.disabled = lockFilters and selectedFilter != Item.Type.ARMOR
		if slot.item.itemType == Item.Type.KEY_ITEM:
			keyItemFilterBtn.disabled = lockFilters and selectedFilter != Item.Type.KEY_ITEM
	
func buy_item(slot: InventorySlot):
	PlayerResources.inventory.add_item(slot.item)
	PlayerResources.playerInfo.gold -= slot.item.cost
	shopInventory.trash_item(slot)
	load_inventory_panel()
	
func sell_item(slot: InventorySlot):
	PlayerResources.inventory.trash_item(slot)
	PlayerResources.playerInfo.gold += slot.item.cost
	shopInventory.add_item(slot.item)
	load_inventory_panel()

func view_item_details(slot: InventorySlot):
	backButton.disabled = true
	itemDetailsPanel.item = slot.item
	itemDetailsPanel.count = slot.count
	itemDetailsPanel.visible = true
	itemDetailsPanel.load_item_details()

func filter_by(type: Item.Type = Item.Type.ALL):
	selectedFilter = type
	load_inventory_panel()
	
func update_toggle_inv_button():
	toggleShopButton.visible = inShop
	toggleShopButton.text = "Show Shop's Inventory" if showPlayerInventory else 'Show Your Inventory'
	
func check_filters():
	var count: int = 0
	for slot in currentInventory.inventorySlots:
		if selectedFilter == Item.Type.ALL or selectedFilter == slot.item.itemType:
			count += 1
	
	if count == 0 and not summoning: # reset filter if no items would be shown (and we aren't summoning)
		selectedFilter = Item.Type.ALL

func update_filter_buttons():
	healingFilterBtn.button_pressed = selectedFilter == Item.Type.HEALING
	shardFilterBtn.button_pressed = selectedFilter == Item.Type.SHARD
	weaponFilterBtn.button_pressed = selectedFilter == Item.Type.WEAPON
	armorFilterBtn.button_pressed = selectedFilter == Item.Type.ARMOR
	keyItemFilterBtn.button_pressed = selectedFilter == Item.Type.KEY_ITEM

func _on_toggle_shop_inventory_button_pressed():
	showPlayerInventory = not showPlayerInventory
	load_inventory_panel()

func _on_back_button_pressed():
	toggle() # hide inventory panel
	back_pressed.emit()
	
func _on_details_back_button_pressed():
	backButton.disabled = false
	initial_focus()

func _on_healing_button_toggled(button_pressed):
	if lockFilters: # ignore toggle if filters are supposed to be locked
		return
	if button_pressed:
		filter_by(Item.Type.HEALING)
	elif selectedFilter == Item.Type.HEALING:
		filter_by()

func _on_shards_button_toggled(button_pressed):
	if lockFilters: # ignore toggle if filters are supposed to be locked
		return
	if button_pressed:
		filter_by(Item.Type.SHARD)
	elif selectedFilter == Item.Type.SHARD:
		filter_by()

func _on_weapons_button_toggled(button_pressed):
	if lockFilters: # ignore toggle if filters are supposed to be locked
		return
	if button_pressed:
		filter_by(Item.Type.WEAPON)
	elif selectedFilter == Item.Type.WEAPON:
		filter_by()
	
func _on_armor_button_toggled(button_pressed):
	if lockFilters: # ignore toggle if filters are supposed to be locked
		return
	if button_pressed:
		filter_by(Item.Type.ARMOR)
	elif selectedFilter == Item.Type.ARMOR:
		filter_by()

func _on_key_items_button_toggled(button_pressed):
	if lockFilters: # ignore toggle if filters are supposed to be locked
		return
	if button_pressed:
		filter_by(Item.Type.KEY_ITEM)
	elif selectedFilter == Item.Type.KEY_ITEM:
		filter_by()

func _on_item_used(slot: InventorySlot):
	if slot.item.get_as_subclass().get_use_message(PlayerResources.playerInfo.combatant) != '' and showItemUsePanel:
		itemUsePanel.item = slot.item
		itemUsePanel.target = PlayerResources.playerInfo.combatant
		itemUsePanel.load_item_use_panel()
		backButton.disabled = true
	elif slot.item.itemType == Item.Type.SHARD and not inBattle:
		itemUsePanel.item = slot.item
		shardLearnPanel.shard = slot.item as Shard
		shardLearnPanel.load_shard_learn_panel()
		backButton.disabled = true

func _on_item_use_panel_ok_pressed():
	backButton.disabled = false
	initial_focus()

func _on_shard_learn_panel_back_pressed():
	backButton.disabled = false
	load_inventory_panel()
	initial_focus()

func _on_shard_learn_panel_learned_move(move: Move):
	itemUsePanel.target = PlayerResources.playerInfo.combatant
	itemUsePanel.learnedMove = move
	itemUsePanel.load_item_use_panel()
