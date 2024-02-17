extends Node2D
class_name InventoryMenu

signal item_used(slot: InventorySlot)
signal open_stats(combatant: Combatant)
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
@onready var equipPanel: EquipPanel = get_node("EquipPanel")
@onready var itemConfirmPanel: ItemConfirmPanel = get_node("ItemConfirmPanel")

var currentInventory: Inventory = null
var otherInventory: Inventory = null # player inventory if looking at NPC shop; NPC inventory if looking at player inventory inside NPC shop

var lastFocused: Control = null
var lastSlotInteracted: InventorySlot = null
var confirmingAction: String = ''
var viewingEquipStats: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func toggle():
	visible = not visible
	if visible:
		get_display_inventory()
		check_filters()
		load_inventory_panel()
		initial_focus()
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
		backButton.disabled = false
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

func restore_last_focus(controlProperty: String):
	get_last_focused_slot_panel()
	if lastFocused == null:
		initial_focus()
	else:
		lastFocused[controlProperty].grab_focus()

func get_last_focused_slot_panel():
	lastFocused = null
	for panel in get_tree().get_nodes_in_group("InventorySlotPanel"):
		if panel.inventorySlot == lastSlotInteracted:
			lastFocused = panel

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
	# and set initial focus neighbors to back
	healingFilterBtn.disabled = true
	healingFilterBtn.focus_neighbor_bottom = healingFilterBtn.get_path_to(backButton)
	
	shardFilterBtn.disabled = true
	shardFilterBtn.focus_neighbor_bottom = shardFilterBtn.get_path_to(backButton)
	
	weaponFilterBtn.disabled = true
	weaponFilterBtn.focus_neighbor_bottom = weaponFilterBtn.get_path_to(backButton)
	
	armorFilterBtn.disabled = true
	armorFilterBtn.focus_neighbor_bottom = armorFilterBtn.get_path_to(backButton)
	
	keyItemFilterBtn.disabled = true
	keyItemFilterBtn.focus_neighbor_bottom = keyItemFilterBtn.get_path_to(backButton)
	
	backButton.focus_neighbor_top = backButton.get_path_to(weaponFilterBtn)
	
	for panel in get_tree().get_nodes_in_group("InventorySlotPanel"):
		panel.queue_free()
	
	inventoryTitle.text = '[center]Inventory[/center]'
	goldCount.text = TextUtils.num_to_comma_string(PlayerResources.playerInfo.gold)
	if inShop:
		if not showPlayerInventory:
			inventoryTitle.text = '[center]Shop Inventory[/center]'
		else:
			inventoryTitle.text = '[center]Your Inventory[/center]'
	
	var firstPanel: bool = true
	var invSlotPanel = load("res://prefabs/ui/inventory/inventory_slot_panel.tscn")
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
			if firstPanel:
				healingFilterBtn.focus_neighbor_bottom = healingFilterBtn.get_path_to(instantiatedPanel.get_leftmost_button())
				shardFilterBtn.focus_neighbor_bottom = shardFilterBtn.get_path_to(instantiatedPanel.get_leftmost_button())
				weaponFilterBtn.focus_neighbor_bottom = weaponFilterBtn.get_path_to(instantiatedPanel.get_leftmost_button())
				armorFilterBtn.focus_neighbor_bottom = armorFilterBtn.get_path_to(instantiatedPanel.get_leftmost_button())
				keyItemFilterBtn.focus_neighbor_bottom = keyItemFilterBtn.get_path_to(instantiatedPanel.get_leftmost_button())
				instantiatedPanel.detailsButton.focus_neighbor_top = instantiatedPanel.detailsButton.get_path_to(keyItemFilterBtn)
				instantiatedPanel.buyButton.focus_neighbor_top = instantiatedPanel.detailsButton.get_path_to(keyItemFilterBtn)
				instantiatedPanel.sellButton.focus_neighbor_top = instantiatedPanel.detailsButton.get_path_to(keyItemFilterBtn)
				instantiatedPanel.equipButton.focus_neighbor_top = instantiatedPanel.detailsButton.get_path_to(keyItemFilterBtn)
				instantiatedPanel.trashButton.focus_neighbor_top = instantiatedPanel.detailsButton.get_path_to(keyItemFilterBtn)
				firstPanel = false
			backButton.focus_neighbor_top = backButton.get_path_to(instantiatedPanel.get_leftmost_button()) # last panel keeps the focus neighbor of the back button
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
	if firstPanel: # if focus still not grabbed by another panel
		initial_focus() # reset focus
	
func buy_item(slot: InventorySlot):
	lastSlotInteracted = slot
	PlayerResources.inventory.add_item(slot.item)
	PlayerResources.playerInfo.gold -= slot.item.cost
	var last = shopInventory.trash_item(slot)
	load_inventory_panel()
	if last:
		initial_focus()
	else:
		restore_last_focus('buyButton')
	
func sell_item(slot: InventorySlot):
	lastSlotInteracted = slot
	var last = PlayerResources.inventory.trash_item(slot)
	PlayerResources.playerInfo.gold += slot.item.cost
	shopInventory.add_item(slot.item)
	load_inventory_panel()
	if last:
		initial_focus()
	else:
		restore_last_focus('sellButton')

func equip_pressed(slot: InventorySlot, alreadyEquipped: bool):
	lastSlotInteracted = slot
	if alreadyEquipped:
		load_inventory_panel()
		restore_last_focus('equipButton')
	else:
		equipPanel.inventorySlot = slot
		equipPanel.load_equip_panel()

func unequip_pressed(slot: InventorySlot):
	lastSlotInteracted = slot
	load_inventory_panel()
	restore_last_focus('equipButton')
	
func trash_pressed(slot: InventorySlot):
	lastSlotInteracted = slot
	itemConfirmPanel.title = 'Trash Item?'
	itemConfirmPanel.description = 'Are you sure you want to trash 1x ' + slot.item.itemName + '?'
	itemConfirmPanel.load_item_confirm_panel()
	confirmingAction = 'trash'

func view_item_details(slot: InventorySlot):
	lastSlotInteracted = slot
	
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
	restore_last_focus('detailsButton')

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
	lastSlotInteracted = slot
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
	if PlayerResources.playerInfo.combatant.would_item_have_effect(slot.item) \
			and slot.item.itemType != Item.Type.SHARD and not inBattle:
		# if not in battle and it would have effect, use it immediately
		var last = PlayerResources.inventory.use_item(slot.item, PlayerResources.playerInfo.combatant)
		if last:
			lastSlotInteracted = null

func _on_item_use_panel_ok_pressed():
	backButton.disabled = false
	load_inventory_panel()
	restore_last_focus('useButton')

func _on_shard_learn_panel_back_pressed():
	backButton.disabled = false
	load_inventory_panel()
	restore_last_focus('useButton')

func _on_shard_learn_panel_learned_move(move: Move):
	itemUsePanel.target = PlayerResources.playerInfo.combatant
	itemUsePanel.learnedMove = move
	itemConfirmPanel.title = 'Learn ' + move.moveName + ' From ' + lastSlotInteracted.item.itemName + '?'
	itemConfirmPanel.description = 'Learning this move will consume the shard. Learn ' + move.moveName + ' and consume the ' + lastSlotInteracted.item.itemName + '?'
	itemConfirmPanel.load_item_confirm_panel()
	confirmingAction = 'shardLearn'

func _on_item_confirm_panel_confirm_option(yes: bool):
	match confirmingAction:
		'trash':
			if yes:
				var last = PlayerResources.inventory.trash_item(lastSlotInteracted)
				if last:
					lastSlotInteracted = null
		'shardLearn':
			if yes:
				PlayerResources.playerInfo.combatant.stats.add_move_to_pool(itemUsePanel.learnedMove)
				var last = PlayerResources.inventory.trash_item(lastSlotInteracted)
				if last:
					lastSlotInteracted = null
				itemUsePanel.load_item_use_panel()
	if yes:
		load_inventory_panel()
	else:
		backButton.disabled = false
	match confirmingAction:
		'trash':
			restore_last_focus('trashButton')
		'shardLearn':
			if not yes: # if yes, the item use panel will capture focus and handle restoring it after
				restore_last_focus('useButton')

func _on_equip_panel_close_equip_panel(combatant: Combatant):
	load_inventory_panel()
	restore_last_focus('equipButton')
	equipPanel.visible = false

func _on_equip_panel_stats_button_pressed(combatant: Combatant):
	open_stats.emit(combatant)
	visible = false
	viewingEquipStats = true

func _on_stats_panel_node_back_pressed():
	if viewingEquipStats:
		visible = true
		equipPanel.restore_focus(true)
	viewingEquipStats = false
