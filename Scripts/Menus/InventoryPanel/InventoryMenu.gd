extends Node2D
class_name InventoryMenu

@export_category("InventoryPanel - Context")
@export var inShop: bool = false
@export var showPlayerInventory = false

@export_category("InventoryPanel - Filters")
@export var selectedFilter: Item.Type = Item.Type.ALL
@export var battleFilter: bool = false
@export var lockFilters: bool = false

@onready var vboxViewport = get_node("InventoryPanel/Panel/ScrollContainer/VBoxContainer")
@onready var toggleShopButton: Button = get_node("InventoryPanel/Panel/ToggleShopInventoryButton")

@onready var healingFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/HealingButton")
@onready var shardFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/ShardsButton")
@onready var weaponFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/WeaponsButton")
@onready var armorFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/ArmorButton")
@onready var keyItemFilterBtn: Button = get_node("InventoryPanel/Panel/HBoxContainer/KeyItemsButton")
@onready var backButton: Button = get_node("InventoryPanel/Panel/BackButton")
@onready var itemDetailsPanel: ItemDetailsPanel = get_node("ItemDetailsPanel")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func toggle():
	visible = not visible
	if visible:
		load_inventory_panel()

func load_inventory_panel():
	update_toggle_inv_button()
	update_filter_buttons()
	
	var existingPanels = get_tree().get_nodes_in_group("InventorySlotPanel")
	for panel in existingPanels:
		panel.queue_free()
	
	var invSlotPanel = load("res://Prefabs/UI/InventorySlotPanel.tscn")
	print(len(PlayerResources.inventory.inventorySlots))
	for slot in PlayerResources.inventory.inventorySlots:
		if selectedFilter == Item.Type.ALL or selectedFilter == slot.item.itemType:
			var instantiatedPanel: InventorySlotPanel = invSlotPanel.instantiate()
			instantiatedPanel.isShopItem = inShop
			instantiatedPanel.isPlayerItem = showPlayerInventory or not inShop
			instantiatedPanel.inventoryMenu = self
			instantiatedPanel.inventorySlot = slot
			vboxViewport.add_child(instantiatedPanel)
	
func buy_item(slot: InventorySlot):
	PlayerResources.inventory.add_item(slot.item)
	PlayerResources.playerInfo.gold -= slot.item.cost
	# TODO remove item from NPC's inventory
	pass
	
func sell_item(slot: InventorySlot):
	PlayerResources.inventory.trash_item(slot)
	PlayerResources.playerInfo.gold += slot.item.cost
	# TODO add item to NPC's inventory
	pass

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

func update_filter_buttons():
	healingFilterBtn.button_pressed = selectedFilter == Item.Type.HEALING
	shardFilterBtn.button_pressed = selectedFilter == Item.Type.SHARD
	weaponFilterBtn.button_pressed = selectedFilter == Item.Type.WEAPON
	armorFilterBtn.button_pressed = selectedFilter == Item.Type.ARMOR
	keyItemFilterBtn.button_pressed = selectedFilter == Item.Type.KEY_ITEM

func _on_toggle_shop_inventory_button_pressed():
	showPlayerInventory = not showPlayerInventory
	update_toggle_inv_button()

func _on_back_button_pressed():
	toggle() # hide inventory panel
	
func _on_details_back_button_pressed():
	backButton.disabled = false

func _on_healing_button_toggled(button_pressed):
	if button_pressed:
		filter_by(Item.Type.HEALING)
	else:
		if selectedFilter == Item.Type.HEALING:
			filter_by()

func _on_shards_button_toggled(button_pressed):
	if button_pressed:
		filter_by(Item.Type.SHARD)
	else:
		if selectedFilter == Item.Type.SHARD:
			filter_by()

func _on_weapons_button_toggled(button_pressed):
	if button_pressed:
		filter_by(Item.Type.WEAPON)
	else:
		if selectedFilter == Item.Type.WEAPON:
			filter_by()
	
func _on_armor_button_toggled(button_pressed):
	if button_pressed:
		filter_by(Item.Type.ARMOR)
	else:
		if selectedFilter == Item.Type.ARMOR:
			filter_by()

func _on_key_items_button_toggled(button_pressed):
	if button_pressed:
		filter_by(Item.Type.KEY_ITEM)
	else:
		if selectedFilter == Item.Type.KEY_ITEM:
			filter_by()
