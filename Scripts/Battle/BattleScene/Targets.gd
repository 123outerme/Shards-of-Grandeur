extends Control
class_name TargetsMenu

@export var battleUI: BattleUI

@onready var commandText: RichTextLabel = get_node("CommandText")
@onready var targetsListing: RichTextLabel = get_node("TargetsListing")
@onready var confirmButton: Button = get_node("ConfirmButton")

var singleSelect: bool = true
var referringMenu: BattleState.Menu = BattleState.Menu.MOVES

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func load_targets():
	commandText.text = '[center]' + battleUI.commandingCombatant.combatant.disp_name() + ' will use '
	
	var targets: BattleCommand.Targets = BattleCommand.Targets.NONE
	if battleUI.commandingCombatant.combatant.command.type == BattleCommand.Type.MOVE:
		commandText.text += battleUI.commandingCombatant.combatant.command.move.moveName
		targets = battleUI.commandingCombatant.combatant.command.move.targets
	if battleUI.commandingCombatant.combatant.command.type == BattleCommand.Type.USE_ITEM:
		commandText.text += battleUI.commandingCombatant.combatant.command.slot.item.itemName
		targets = battleUI.commandingCombatant.combatant.command.slot.item.battleTargets
	
	singleSelect = not BattleCommand.is_command_multi_target(targets)
	commandText.text += '.[/center]'
	
	var allCombatantNodes: Array[CombatantNode] = battleUI.battleController.get_all_combatant_nodes()
	for combatantNode in allCombatantNodes:
		if combatantNode.is_alive():
			combatantNode.toggled.connect(_on_combatant_selected)
		combatantNode.update_select_btn(false)
	
	var targetableCombatants: Array[CombatantNode] = battleUI.commandingCombatant.get_targetable_combatant_nodes(allCombatantNodes, targets)
	for targetableCombatant in targetableCombatants:
		targetableCombatant.update_select_btn(true, not singleSelect)
	
	update_targets_listing()
	update_confirm_btn()
	
func update_targets_listing(button_pressed: bool = false, combatantNode: CombatantNode = null):
	var names: Array[String] = []
	for cNode in battleUI.battleController.get_all_combatant_nodes():
		if combatantNode != null:
			if singleSelect:
				if button_pressed and combatantNode != cNode:
					cNode.set_selected(false) # single select: deselect anything not just selected
		if not singleSelect and cNode.is_alive() and cNode.selectCombatantBtn.visible:
			cNode.set_selected(true)
		if cNode.is_selected():
			names.append(cNode.combatant.stats.displayName)
		
	if len(names) == 0:
		targetsListing.text = '[center]No Targets Selected[/center]'
	else:
		var listing: String = ''
		for i in range(len(names)):
			listing += names[i]
			if len(names) > 1 and i < len(names) - 1: # if multiple names and not at the last name
				if len(names) > 2:
					listing += ','
				listing += ' '
				if i == len(names) - 2: # if this is the second-to-last item, append "and" to the string for the last
					listing += 'and '
		targetsListing.text = '[center]' + listing + '[/center]'
	
func update_confirm_btn():
	var confirmDisabled: bool = true
	for combatantNode in battleUI.battleController.get_all_combatant_nodes():
		if combatantNode.is_selected():
			confirmDisabled = false
	confirmButton.disabled = confirmDisabled

func reset_targets():
	for cNode in battleUI.battleController.get_all_combatant_nodes():
		if cNode.is_alive():
			cNode.toggled.disconnect(_on_combatant_selected)
			cNode.set_selected(false)
			cNode.update_select_btn(false)

func _on_combatant_selected(button_pressed: bool, combatantNode: CombatantNode):
	update_targets_listing(button_pressed, combatantNode)
	update_confirm_btn()

func _on_confirm_button_pressed():
	var targetPositions: Array[String] = []
	for combatantNode in battleUI.battleController.get_all_combatant_nodes():
		if combatantNode.is_selected():
			targetPositions.append(combatantNode.battlePosition)
	battleUI.commandingCombatant.combatant.command.set_targets(targetPositions)
	
	reset_targets()
	battleUI.complete_command()

func _on_back_button_pressed():
	reset_targets()
	battleUI.set_menu_state(referringMenu)
