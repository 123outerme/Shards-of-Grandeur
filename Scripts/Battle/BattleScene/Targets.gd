extends Control
class_name TargetsMenu

@export var battleUI: BattleUI

@onready var targetsListing: RichTextLabel = get_node("TargetsListing")
@onready var confirmButton: Button = get_node("ConfirmButton")

var singleSelect: bool = true
var referringMenu: BattleState.Menu = BattleState.Menu.MOVES

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func load_targets():
	for node in battleUI.battleController.combatantNodes:
		var combatantNode: CombatantNode = node as CombatantNode
		if not combatantNode.is_alive():
			continue # go to the next node, this combatant is not alive
		
		var targets: BattleCommand.Targets = BattleCommand.Targets.NONE
		
		if battleUI.commandingCombatant.combatant.command.type == BattleCommand.Type.MOVE:
			targets = battleUI.commandingCombatant.combatant.command.move.targets
				
		if battleUI.commandingCombatant.combatant.command.type == BattleCommand.Type.USE_ITEM:
			targets = battleUI.commandingCombatant.combatant.command.slot.item.battleTargets
		
		if (targets == BattleCommand.Targets.ALL_ALLIES and combatantNode.role == CombatantNode.Role.ALLY) \
				or (targets == BattleCommand.Targets.ALL_ENEMIES and combatantNode.role == CombatantNode.Role.ENEMY) \
				or (targets == BattleCommand.Targets.SELF and combatantNode == battleUI.commandingCombatant):
			combatantNode.update_select_btn(true, false)
			combatantNode.select_combatant()
			# if targeting all enemies, all allies, or just self, target is obvious, select and lock chosen type
		
		if combatantNode.role == CombatantNode.Role.ALLY: # if node role is Ally
			if targets == BattleCommand.Targets.NON_SELF_ALLY and combatantNode != battleUI.commandingCombatant \
					# if node is non-self and targeting non-self ally
					or targets == BattleCommand.Targets.ALLY: # or if targeting ally
				combatantNode.update_select_btn(true) # show target btn
		if combatantNode.role == combatantNode.Role.ENEMY and targets == BattleCommand.Targets.ENEMY:
			combatantNode.update_select_btn(true) # if enemy and targeting enemy, show target btn
		combatantNode.toggled.connect(_on_combatant_selected)
	update_targets_listing()
	update_confirm_btn()
	
func update_targets_listing(button_pressed: bool = false, combatantNode: CombatantNode = null):
	var names: Array[String] = []
	for node in battleUI.battleController.combatantNodes:
		var cNode: CombatantNode = node as CombatantNode
		if singleSelect and combatantNode != null:
			if button_pressed and combatantNode != cNode:
				cNode.set_selected(false) # single select: deselect anything not just selected
		if cNode.is_selected():
			names.append(cNode.combatant.stats.displayName)
		
	if len(names) == 0:
		targetsListing.text = '[center]No Targets Selected[/center]'
	else:
		var listing: String = ''
		for i in range(len(names)):
			listing += names[i]
			if len(names) > 1 and i < len(names) - 1: # if multiple names and not at the last name
				listing += ', '
				if i == len(names) - 2: # if this is the second-to-last item, append "and" to the string for the last
					listing += 'and '
		targetsListing.text = '[center]' + listing + '[/center]'
	
func update_confirm_btn():
	var confirmDisabled: bool = true
	for node in battleUI.battleController.combatantNodes:
		var combatantNode: CombatantNode = node as CombatantNode
		if combatantNode.is_selected():
			confirmDisabled = false
	confirmButton.disabled = confirmDisabled

func reset_targets():
	for node in battleUI.battleController.combatantNodes:
		var cNode: CombatantNode = node as CombatantNode
		if cNode.is_alive():
			cNode.toggled.disconnect(_on_combatant_selected)
			cNode.set_selected(false)
			cNode.update_select_btn(false)

func _on_combatant_selected(button_pressed: bool, combatantNode: CombatantNode):
	update_targets_listing(button_pressed, combatantNode)
	update_confirm_btn()

func _on_confirm_button_pressed():
	battleUI.commandingCombatant.combatant.command.targets = []
	for node in battleUI.battleController.combatantNodes:
		var combatantNode: CombatantNode = node as CombatantNode
		if combatantNode.is_selected():
			battleUI.commandingCombatant.combatant.command.targets.append(combatantNode.combatant)
	
	reset_targets()
	battleUI.complete_command()

func _on_back_button_pressed():
	reset_targets()
	battleUI.set_menu_state(referringMenu)
