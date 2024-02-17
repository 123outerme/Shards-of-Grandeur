extends Control
class_name EquipPanel

signal stats_button_pressed(combatant: Combatant)
signal close_equip_panel(combatant: Combatant)

@export var inventorySlot: InventorySlot = null

var lastCombatant: Combatant = null
var playerPanel: EquipCombatantPanel = null

var equipCombatantPanelScene: PackedScene = preload('res://prefabs/ui/inventory/equip_combatant_panel.tscn')

@onready var equipTitle: RichTextLabel = get_node('Panel/EquipTitle')
@onready var itemSprite: Sprite2D = get_node('Panel/ItemSpriteControl/ItemSprite')
@onready var itemEffect: RichTextLabel = get_node('Panel/ItemEffect')
@onready var vboxContainer: VBoxContainer = get_node('Panel/ScrollContainer/VBoxContainer')

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func load_equip_panel(initial: bool = true):
	visible = true
	
	equipTitle.text = '[center]Equip - ' + inventorySlot.item.itemName + '[/center]'
	itemSprite.texture = inventorySlot.item.itemSprite
	itemEffect.text = '[center]' + inventorySlot.item.get_effect_text() + '[/center]'
	for panel in get_tree().get_nodes_in_group('EquipCombatantPanel'):
		panel.combatant = null
		panel.queue_free()
	
	playerPanel = equipCombatantPanelScene.instantiate()
	playerPanel.combatant = PlayerResources.playerInfo.combatant
	playerPanel.item = inventorySlot.item
	playerPanel.parentPanel = self
	vboxContainer.add_child(playerPanel)
	if initial:
		playerPanel.call_deferred('initial_focus')
	
	for minion in PlayerResources.minions.get_minion_list():
		var panel: EquipCombatantPanel = equipCombatantPanelScene.instantiate()
		panel.combatant = minion
		panel.item = inventorySlot.item
		panel.parentPanel = self
		vboxContainer.add_child(panel)

func restore_focus(statsButton: bool = false):
	if lastCombatant == null:
		playerPanel.call_deferred('initial_focus')
	else:
		for panel: EquipCombatantPanel in get_tree().get_nodes_in_group('EquipCombatantPanel'):
			if panel.combatant == lastCombatant:
				if statsButton:
					panel.call_deferred('focus_stats_button')
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
	close_equip_panel.emit(combatant)

func unequip_pressed(combatant: Combatant):
	combatant.stats.unequip_item(inventorySlot.item)
	lastCombatant = combatant
	load_equip_panel(false)
	call_deferred('restore_focus')

func _on_back_button_pressed():
	close_equip_panel.emit(null)
