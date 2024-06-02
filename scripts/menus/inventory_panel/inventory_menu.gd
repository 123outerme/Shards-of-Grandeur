extends Node2D
class_name InventoryMenu

signal item_used(slot: InventorySlot)
signal open_stats(combatant: Combatant)
signal back_pressed
signal learn_shard_tutorial_finished

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

@onready var allFilterBtn: Button = get_node('InventoryPanel/Panel/HBoxContainer/AllButton')
@onready var healingFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/HealingButton")
@onready var shardFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/ShardsButton")
@onready var weaponFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/WeaponsButton")
@onready var armorFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/ArmorButton")
@onready var keyItemFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/KeyItemsButton")
@onready var backButton: Button = get_node("InventoryPanel/Panel/BackButton")

@onready var learnShardTutorialShade: ColorRect = get_node('InventoryPanel/Panel/LearnShardTutorialShade')
@onready var tutorialArrowControl: Control = get_node('InventoryPanel/Panel/LearnShardTutorialShade/TutorialArrowControl')
@onready var tutorialArrow: AnimatedSprite2D = get_node('InventoryPanel/Panel/LearnShardTutorialShade/TutorialArrowControl/TutorialArrowSprite')

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
var viewingEquipItemDetails: bool = false
var inShardLearnTutorial: bool = false
var shardTutorialSlotPanel: InventorySlotPanel = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed('game_decline') and not inShardLearnTutorial:
		get_viewport().set_input_as_handled()
		toggle()

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
		equipPanel.visible = false
		itemConfirmPanel.visible = false
		backButton.disabled = false
		if equipContextStats != null:
			lockFilters = false
			selectedFilter = Item.Type.ALL
		equipContextStats = null
		viewingEquipStats = false
		viewingEquipItemDetails = false
		backButton.disabled = false
		back_pressed.emit()

func initial_focus():
	var centerMostFilter: Button = get_centermost_filter()
	if centerMostFilter != null:
		centerMostFilter.grab_focus()
		return
	
	backButton.grab_focus()

func get_centermost_filter() -> Button:
	# order: weapon -> shard -> armor -> healing -> key items
	if not weaponFilterBtn.disabled:
		return weaponFilterBtn
		
	if not shardFilterBtn.disabled:
		return shardFilterBtn
	
	if not armorFilterBtn.disabled:
		return armorFilterBtn
	
	if not healingFilterBtn.disabled:
		return healingFilterBtn
		
	if not keyItemFilterBtn.disabled:
		return keyItemFilterBtn
		
	if not allFilterBtn.disabled:
		return allFilterBtn
	
	return null

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

func load_inventory_panel(rebuild: bool = true):
	get_display_inventory()
	update_toggle_inv_button()
	update_filter_buttons()
	# lock all filters so that they can be unlocked as the inventory slots get created
	# and set initial focus neighbors to back
	if rebuild:
		allFilterBtn.disabled = lockFilters
		allFilterBtn.focus_neighbor_top = allFilterBtn.get_path_to(toggleShopButton if toggleShopButton.visible else backButton)
		allFilterBtn.focus_neighbor_bottom = allFilterBtn.get_path_to(backButton)
		
		healingFilterBtn.disabled = true
		healingFilterBtn.focus_neighbor_top = healingFilterBtn.get_path_to(toggleShopButton if toggleShopButton.visible else backButton)
		healingFilterBtn.focus_neighbor_bottom = healingFilterBtn.get_path_to(backButton)
		
		shardFilterBtn.disabled = true
		shardFilterBtn.focus_neighbor_top = shardFilterBtn.get_path_to(toggleShopButton if toggleShopButton.visible else backButton)
		shardFilterBtn.focus_neighbor_bottom = shardFilterBtn.get_path_to(backButton)
		
		weaponFilterBtn.disabled = true
		weaponFilterBtn.focus_neighbor_top = weaponFilterBtn.get_path_to(toggleShopButton if toggleShopButton.visible else backButton)
		weaponFilterBtn.focus_neighbor_bottom = weaponFilterBtn.get_path_to(backButton)
		
		armorFilterBtn.disabled = true
		armorFilterBtn.focus_neighbor_top = armorFilterBtn.get_path_to(toggleShopButton if toggleShopButton.visible else backButton)
		armorFilterBtn.focus_neighbor_bottom = armorFilterBtn.get_path_to(backButton)
		
		keyItemFilterBtn.disabled = true
		keyItemFilterBtn.focus_neighbor_top = keyItemFilterBtn.get_path_to(toggleShopButton if toggleShopButton.visible else backButton)
		keyItemFilterBtn.focus_neighbor_bottom = keyItemFilterBtn.get_path_to(backButton)
	
	inventoryTitle.text = '[center]Inventory[/center]'
	goldCount.text = TextUtils.num_to_comma_string(PlayerResources.playerInfo.gold)
	
	if inShop:
		if not showPlayerInventory:
			inventoryTitle.text = '[center]Shop Inventory[/center]'
		else:
			inventoryTitle.text = '[center]Your Inventory[/center]'
	
	if rebuild:
		for panel in get_tree().get_nodes_in_group("InventorySlotPanel"):
			panel.queue_free()
		
		var firstPanel: InventorySlotPanel = null
		var invSlotPanel = load("res://prefabs/ui/inventory/inventory_slot_panel.tscn")
		for slot in currentInventory.get_sorted_slots():
			if slot.count == 0:
				continue
			if slot is ShopInventorySlot:
				var shopSlot: ShopInventorySlot = slot as ShopInventorySlot
				if not shopSlot.is_valid():
					continue
			if (selectedFilter == Item.Type.ALL or selectedFilter == slot.item.itemType) and slot.is_valid():
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
				if firstPanel == null:
					firstPanel = instantiatedPanel
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
		if firstPanel != null: # if focus still not grabbed by another panel
			allFilterBtn.focus_neighbor_bottom = allFilterBtn.get_path_to(firstPanel.get_leftmost_button())
			healingFilterBtn.focus_neighbor_bottom = healingFilterBtn.get_path_to(firstPanel.get_leftmost_button())
			shardFilterBtn.focus_neighbor_bottom = shardFilterBtn.get_path_to(firstPanel.get_leftmost_button())
			weaponFilterBtn.focus_neighbor_bottom = weaponFilterBtn.get_path_to(firstPanel.get_leftmost_button())
			armorFilterBtn.focus_neighbor_bottom = armorFilterBtn.get_path_to(firstPanel.get_leftmost_button())
			keyItemFilterBtn.focus_neighbor_bottom = keyItemFilterBtn.get_path_to(firstPanel.get_leftmost_button())
			firstPanel.detailsButton.focus_neighbor_top = firstPanel.detailsButton.get_path_to(get_centermost_filter())
			firstPanel.buyButton.focus_neighbor_top = firstPanel.detailsButton.get_path_to(get_centermost_filter())
			firstPanel.sellButton.focus_neighbor_top = firstPanel.detailsButton.get_path_to(get_centermost_filter())
			firstPanel.equipButton.focus_neighbor_top = firstPanel.detailsButton.get_path_to(get_centermost_filter())
			firstPanel.trashButton.focus_neighbor_top = firstPanel.detailsButton.get_path_to(get_centermost_filter())
		else:
			# no item panels exist
			if toggleShopButton.visible:
				backButton.focus_neighbor_bottom = backButton.get_path_to(toggleShopButton)
			elif get_centermost_filter() != null:
				backButton.focus_neighbor_bottom = backButton.get_path_to(get_centermost_filter())
			else:
				backButton.focus_neighbor_bottom = backButton.get_path_to(weaponFilterBtn)
	else:
		for panel: InventorySlotPanel in get_tree().get_nodes_in_group("InventorySlotPanel"):
			panel.load_inventory_slot_panel()
	
func buy_item(slot: InventorySlot):
	lastSlotInteracted = slot
	PlayerResources.inventory.add_item(slot.item)
	var full: bool = false
	if PlayerResources.inventory.is_slot_for_item_full(slot.item):
		full = true
	PlayerResources.playerInfo.gold -= slot.item.cost
	var last = shopInventory.trash_item(slot)
	load_inventory_panel(last or full)
	if last:
		initial_focus()
	else:
		restore_last_focus('buyButton')
	
func sell_item(slot: InventorySlot):
	lastSlotInteracted = slot
	var last = PlayerResources.inventory.trash_item(slot)
	PlayerResources.playerInfo.gold += slot.item.cost
	shopInventory.add_item(slot.item)
	var full: bool = false
	if shopInventory.is_slot_for_item_full(slot.item):
		full = true
	load_inventory_panel(last or full)
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
		backButton.disabled = true
	
func trash_pressed(slot: InventorySlot):
	lastSlotInteracted = slot
	itemConfirmPanel.title = 'Trash Item?'
	itemConfirmPanel.description = 'Are you sure you want to trash 1x ' + slot.item.itemName \
			+ '? You will get ' + String.num(roundi(slot.item.cost / 2.0)) + ' gold from trashing it.'
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
	allFilterBtn.button_pressed = selectedFilter == Item.Type.ALL
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
	if viewingEquipItemDetails:
		equipPanel.restore_focus('details')
	else:
		restore_last_focus('detailsButton')
	viewingEquipItemDetails = false

func _on_all_button_toggled(button_pressed):
	if lockFilters:
		return
	if button_pressed:
		filter_by()

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
		shardLearnPanel.inTutorial = inShardLearnTutorial
		if inShardLearnTutorial:
			shardTutorialSlotPanel.z_index = 0
			learnShardTutorialShade.visible = false
			tutorialArrow.stop()
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
	if inShardLearnTutorial:
		inShardLearnTutorial = false
		shardTutorialSlotPanel = null
		learn_shard_tutorial_finished.emit()
		toggle() # hide the panel
		return
	load_inventory_panel(lastSlotInteracted == null)
	restore_last_focus('useButton')

func _on_shard_learn_panel_back_pressed():
	backButton.disabled = false
	load_inventory_panel(false)
	restore_last_focus('useButton')

func _on_shard_learn_panel_learned_move(move: Move):
	itemUsePanel.target = PlayerResources.playerInfo.combatant
	itemUsePanel.learnedMove = move
	itemConfirmPanel.title = 'Learn ' + move.moveName + ' From ' + lastSlotInteracted.item.itemName + '?'
	itemConfirmPanel.description = 'Learning this move will consume the shard. Learn ' + move.moveName + ' and consume the ' + lastSlotInteracted.item.itemName + '?'
	itemConfirmPanel.forceConfirm = inShardLearnTutorial
	itemConfirmPanel.load_item_confirm_panel()
	confirmingAction = 'shardLearn'

func _on_item_confirm_panel_confirm_option(yes: bool):
	match confirmingAction:
		'trash':
			if yes:
				var last = PlayerResources.inventory.trash_item(lastSlotInteracted)
				PlayerResources.playerInfo.gold += roundi(lastSlotInteracted.item.cost / 2.0)
				if last:
					lastSlotInteracted = null
		'shardLearn':
			if yes:
				var playerCombatant: Combatant = PlayerResources.playerInfo.combatant
				playerCombatant.stats.add_move_to_pool(itemUsePanel.learnedMove)
				# if the player is in an evolution right now, also add this move to the base form stats for keeping track of learned moves
				if playerCombatant.get_evolution() != null:
					playerCombatant.get_evolution_stats(null).stats.add_move_to_pool(itemUsePanel.learnedMove)
				
				var shard: Shard = lastSlotInteracted.item as Shard
				# add Attunement for minion whose shard you used
				PlayerResources.minions.add_friendship(shard.combatantSaveName, true)
				var last = PlayerResources.inventory.trash_item(lastSlotInteracted)
				if last:
					lastSlotInteracted = null
				itemUsePanel.load_item_use_panel()
	if yes:
		load_inventory_panel(lastSlotInteracted == null)
	else:
		backButton.disabled = false
	match confirmingAction:
		'trash':
			restore_last_focus('trashButton')
		'shardLearn':
			if not yes: # if yes, the item use panel will capture focus and handle restoring it after
				restore_last_focus('useButton')

func _on_equip_panel_close_equip_panel():
	load_inventory_panel()
	restore_last_focus('equipButton')
	equipPanel.visible = false
	backButton.disabled = false

func _on_equip_panel_stats_button_pressed(combatant: Combatant):
	open_stats.emit(combatant)
	visible = false
	viewingEquipStats = true

func _on_stats_panel_node_back_pressed():
	if viewingEquipStats:
		visible = true
		equipPanel.restore_focus('stats')
	viewingEquipStats = false

func _on_equip_panel_show_details_for_item(item: Item):
	itemDetailsPanel.item = item
	itemDetailsPanel.count = 0
	itemDetailsPanel.load_item_details()
	itemDetailsPanel.visible = true
	viewingEquipItemDetails = true

func start_learn_shard_tutorial():
	var treeBearShard: Shard = load('res://gamedata/items/shard/tree_bear_shard.tres')
	# ensure the player has a Tree Bear Shard to use - give it for free!
	PlayerResources.inventory.add_item(treeBearShard)
	inShardLearnTutorial = true
	# reload the inventory (in case we added a new shard)
	if not visible:
		toggle()
	else:
		load_inventory_panel(true)
	await get_tree().process_frame
	shardTutorialSlotPanel = null
	# find the panel for the Tree Bear Shard
	for panel in get_tree().get_nodes_in_group('InventorySlotPanel'):
		var slotPanel: InventorySlotPanel = panel as InventorySlotPanel
		if slotPanel.inventorySlot.item == treeBearShard:
			shardTutorialSlotPanel = panel
	# enable "tutorial mode" visuals - shade, tutorial pointing arrow, locked into pressing Use
	backButton.disabled = true
	learnShardTutorialShade.visible = true
	shardTutorialSlotPanel.z_index = 1
	shardTutorialSlotPanel.detailsButton.disabled = true
	shardTutorialSlotPanel.trashButton.disabled = true
	shardTutorialSlotPanel.useButton.grab_focus()
	shardTutorialSlotPanel.useButton.focus_neighbor_bottom = NodePath('.')
	shardTutorialSlotPanel.useButton.focus_neighbor_top = NodePath('.')
	shardTutorialSlotPanel.useButton.focus_neighbor_left = NodePath('.')
	shardTutorialSlotPanel.useButton.focus_neighbor_right = NodePath('.')
	tutorialArrowControl.global_position = shardTutorialSlotPanel.tutorialArrowTargetControl.global_position
	tutorialArrow.play()
