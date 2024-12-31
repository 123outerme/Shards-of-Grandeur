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
@onready var equipmentDetailsPanel: EquipmentDetailsPanel = get_node('Panel/EquipmentDetailsPanel')
@onready var scrollContainer: ScrollBetterFollow = get_node('Panel/ScrollContainer')
@onready var vboxContainer: VBoxContainer = get_node('Panel/ScrollContainer/VBoxContainer')
@onready var backButton: Button = get_node('Panel/BackButton')
@onready var evolveResultsPanel: EvolveResultsPanel = get_node('EvolveResultsPanel')

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
	
		for minion in PlayerResources.minions.get_minion_list():
			var panel: EquipCombatantPanel = equipCombatantPanelScene.instantiate()
			panel.combatant = minion
			panel.item = inventorySlot.item
			panel.parentPanel = self
			vboxContainer.add_child(panel)
			bottomCombatantPanel = panel
		
		bottomCombatantPanel.call_deferred('connect_to_equip_button', backButton, true)
		scrollContainer.set_deferred('scroll_vertical', 0)
	else:
		for panel: EquipCombatantPanel in get_tree().get_nodes_in_group('EquipCombatantPanel'):
			panel.load_equip_combatant_panel()
	
	equipmentDetailsPanel.item = inventorySlot.item
	equipmentDetailsPanel.load_equipment_details_panel()
	equipTitle.text = '[center]Equip - ' + inventorySlot.item.itemName + '[/center]'
	itemSprite.texture = inventorySlot.item.itemSprite
	playerPanel.call_deferred('connect_to_equip_button', backButton, false)

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
	lastCombatant = combatant
	stats_button_pressed.emit(combatant)
	
func equip_pressed(combatant: Combatant):
	var prevEvolution: Evolution = combatant.get_evolution()
	# assumption: only one combatant will lose its evolution at a time if equipping this item
	var combatantLosingPrevEvolution: Evolution = null
	var combatantLosingEvolving: Combatant = null
	var combatantLosingFlags: int = 0
	var combatantList: Array[Combatant] = [PlayerResources.playerInfo.combatant]
	combatantList.append_array(PlayerResources.minions.get_minion_list())
	for unequippingCombatant: Combatant in combatantList:
		var prevLosingEvolution: Evolution = unequippingCombatant.get_evolution()
		unequippingCombatant.stats.unequip_item(inventorySlot.item)
		var newLosingEvolution: Evolution = unequippingCombatant.get_evolution()
		if prevLosingEvolution != newLosingEvolution:
			combatantLosingPrevEvolution = prevLosingEvolution
			combatantLosingEvolving = unequippingCombatant
			combatantLosingFlags = combatantLosingEvolving.switch_evolution(newLosingEvolution, prevLosingEvolution, combatantLosingEvolving != PlayerResources.playerInfo.combatant)
	
	combatant.stats.equip_item(inventorySlot.item)
	#close_equip_panel.emit()
	lastCombatant = combatant
	var newEvolution: Evolution = combatant.get_evolution()
	if newEvolution != prevEvolution:
		evolveResultsPanel.combatant = combatant
		evolveResultsPanel.newEvolution = newEvolution
		evolveResultsPanel.prevEvolution = prevEvolution
		evolveResultsPanel.equipment = inventorySlot.item
		var flags: int = combatant.switch_evolution(newEvolution, prevEvolution, combatant != PlayerResources.playerInfo.combatant)
		evolveResultsPanel.switchEvolutionFlags = flags
		evolveResultsPanel.combatantLosingEvolving = combatantLosingEvolving
		evolveResultsPanel.load_evolve_results_panel()
	elif combatantLosingEvolving != null:
		evolveResultsPanel.combatant = combatantLosingEvolving
		evolveResultsPanel.newEvolution = combatantLosingEvolving.get_evolution()
		evolveResultsPanel.prevEvolution = combatantLosingPrevEvolution
		evolveResultsPanel.equipment = inventorySlot.item
		evolveResultsPanel.switchEvolutionFlags = combatantLosingFlags
		evolveResultsPanel.combatantLosingEvolving = null
		evolveResultsPanel.load_evolve_results_panel()
	else:
		call_deferred('restore_focus')
	load_equip_panel(false)

func unequip_pressed(combatant: Combatant):
	var prevEvolution: Evolution = combatant.get_evolution()
	combatant.stats.unequip_item(inventorySlot.item)
	lastCombatant = combatant
	var newEvolution: Evolution = combatant.get_evolution()
	if newEvolution != prevEvolution:
		evolveResultsPanel.combatant = combatant
		evolveResultsPanel.newEvolution = newEvolution
		evolveResultsPanel.prevEvolution = prevEvolution
		evolveResultsPanel.equipment = inventorySlot.item
		var flags = combatant.switch_evolution(newEvolution, prevEvolution, combatant != PlayerResources.playerInfo.combatant)
		evolveResultsPanel.switchEvolutionFlags = flags
		evolveResultsPanel.combatantLosingEvolving = null
		evolveResultsPanel.load_evolve_results_panel()
	else:
		call_deferred('restore_focus')
	load_equip_panel(false)

func show_item_details(combatant: Combatant, item: Item):
	lastCombatant = combatant
	show_details_for_item.emit(item)

func _on_back_button_pressed():
	close_equip_panel.emit()

func _on_tooltip_panel_ok_pressed():
	call_deferred('restore_focus')
