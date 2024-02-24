extends Control
class_name EquipPanel

signal stats_button_pressed(combatant: Combatant)
signal show_details_for_item(item: Item)
signal close_equip_panel

@export var inventorySlot: InventorySlot = null

var lastCombatant: Combatant = null
var playerPanel: EquipCombatantPanel = null
var bottomCombatantPanel: EquipCombatantPanel = null

var equipCombatantPanelScene: PackedScene = preload('res://prefabs/ui/inventory/equip_combatant_panel.tscn')

@onready var equipTitle: RichTextLabel = get_node('Panel/EquipTitle')
@onready var itemSprite: Sprite2D = get_node('Panel/ItemSpriteControl/ItemSprite')
@onready var itemEffect: RichTextLabel = get_node('Panel/ItemEffect')
@onready var vboxContainer: VBoxContainer = get_node('Panel/ScrollContainer/VBoxContainer')
@onready var backButton: Button = get_node('Panel/BackButton')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _unhandled_input(event):
	if visible and event.is_action_pressed("game_decline"):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed()

func load_equip_panel(initial: bool = true):
	visible = true
	
	if initial:
		for panel in get_tree().get_nodes_in_group('EquipCombatantPanel'):
			panel.combatant = null
			panel.queue_free()
		
		playerPanel = equipCombatantPanelScene.instantiate()
		playerPanel.combatant = PlayerResources.playerInfo.combatant
		playerPanel.item = inventorySlot.item
		playerPanel.parentPanel = self
		vboxContainer.add_child(playerPanel)
		playerPanel.call_deferred('initial_focus')
		bottomCombatantPanel = playerPanel
		playerPanel.call_deferred('connect_to_equip_button', backButton, false)
	
		for minion in PlayerResources.minions.get_minion_list():
			var panel: EquipCombatantPanel = equipCombatantPanelScene.instantiate()
			panel.combatant = minion
			panel.item = inventorySlot.item
			panel.parentPanel = self
			vboxContainer.add_child(panel)
			bottomCombatantPanel = panel
		
		bottomCombatantPanel.call_deferred('connect_to_equip_button', backButton, true)
	else:
		for panel: EquipCombatantPanel in get_tree().get_nodes_in_group('EquipCombatantPanel'):
			panel.load_equip_combatant_panel()
	
	equipTitle.text = '[center]Equip - ' + inventorySlot.item.itemName + '[/center]'
	itemSprite.texture = inventorySlot.item.itemSprite

func restore_focus(button: String = ''):
	if lastCombatant == null:
		playerPanel.call_deferred('initial_focus')
	else:
		for panel: EquipCombatantPanel in get_tree().get_nodes_in_group('EquipCombatantPanel'):
			if panel.combatant == lastCombatant:
				if button == 'stats':
					panel.call_deferred('focus_stats_button')
				elif button == 'details':
					panel.call_deferred('focus_details_button')
				else:
					panel.call_deferred('initial_focus')
				break

func stats_pressed(combatant: Combatant):
	stats_button_pressed.emit(combatant)
	lastCombatant = combatant
	
func equip_pressed(combatant: Combatant):
	PlayerResources.playerInfo.combatant.stats.unequip_item(inventorySlot.item)
		
	for minion in PlayerResources.minions.get_minion_list():
		minion.stats.unequip_item(inventorySlot.item)
	
	combatant.stats.equip_item(inventorySlot.item)
	#close_equip_panel.emit()
	lastCombatant = combatant
	load_equip_panel(false)
	call_deferred('restore_focus')

func unequip_pressed(combatant: Combatant):
	combatant.stats.unequip_item(inventorySlot.item)
	lastCombatant = combatant
	load_equip_panel(false)
	call_deferred('restore_focus')

func show_item_details(combatant: Combatant, item: Item):
	show_details_for_item.emit(item)
	lastCombatant = combatant

func _on_back_button_pressed():
	close_equip_panel.emit()
