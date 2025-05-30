extends Control
class_name TargetsMenu

@export var battleUI: BattleUI

@onready var commandText: RichTextLabel = get_node("CommandText")
@onready var targetsListing: RichTextLabel = get_node("TargetsListing")
@onready var effectDesc: RichTextLabel = get_node('EffectDesc')
@onready var confirmButton: Button = get_node("ConfirmButton")
@onready var backButton: Button = get_node("BackButton")

var moveEffect: MoveEffect = null
var singleSelect: bool = true
var referringMenu: BattleState.Menu = BattleState.Menu.CHARGE_MOVES # default does not matter

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _unhandled_input(event):
	if visible and event.is_action_pressed('game_decline'):
		get_viewport().set_input_as_handled()
		_on_back_button_pressed.call_deferred()

func initial_focus():
	backButton.grab_focus()

func load_targets():
	commandText.text = '[center]' + battleUI.commandingCombatant.combatant.disp_name() + ' will use '
	
	var targets: BattleCommand.Targets = BattleCommand.Targets.NONE
	if battleUI.commandingCombatant.combatant.command.type == BattleCommand.Type.MOVE:
		var move: Move = battleUI.commandingCombatant.combatant.command.move
		moveEffect = move.get_effect_of_type(battleUI.commandingCombatant.combatant.command.moveEffectType)
		if moveEffect == null:
			printerr('Cannot find move effect for ', battleUI.commandingCombatant.combatant.command.move.moveName)
		commandText.text += move.moveName
		targets = moveEffect.targets
		var effectTexts: Array[String] = moveEffect.get_short_description(
			battleUI.commandingCombatant.combatant.command.move.category,
			battleUI.commandingCombatant.combatant.command.move.element
		)
		effectDesc.text = '[center]'
		for text in effectTexts:
			effectDesc.text += TextUtils.rich_text_substitute(text, Vector2i(32, 32)) + '\n'
		effectDesc.text += '[/center]'
	else:
		moveEffect = null
	if battleUI.commandingCombatant.combatant.command.type == BattleCommand.Type.USE_ITEM:
		commandText.text += battleUI.commandingCombatant.combatant.command.slot.item.itemName
		targets = battleUI.commandingCombatant.combatant.command.slot.item.battleTargets
		effectDesc.text = '[center]' + TextUtils.rich_text_substitute(battleUI.commandingCombatant.combatant.command.slot.item.get_effect_text(true), Vector2i(32, 32)) + '[/center]'
	
	singleSelect = not BattleCommand.is_command_multi_target(targets)
	commandText.text += '.[/center]'
	
	var allCombatantNodes: Array[CombatantNode] = battleUI.battleController.get_all_combatant_nodes()
	for combatantNode in allCombatantNodes:
		if combatantNode.is_alive():
			combatantNode.toggled.connect(_on_combatant_selected)
		combatantNode.update_select_btn(false)
	
	var targetableCombatants: Array[CombatantNode] = battleUI.commandingCombatant.get_targetable_combatant_nodes(allCombatantNodes, targets)
	
	var anyShouldTargetAlly: bool = false
	if battleUI.commandingCombatant.combatant.command.type == BattleCommand.Type.USE_ITEM:
		anyShouldTargetAlly = true
	elif battleUI.commandingCombatant.combatant.command.type == BattleCommand.Type.MOVE and moveEffect != null:
		anyShouldTargetAlly = moveEffect.role == MoveEffect.Role.BUFF or moveEffect.role == MoveEffect.Role.HEAL
	
	var focusedCombatant: CombatantNode = null
	# prefer targeting the combatant being commanded, if current command can target self
	if battleUI.commandingCombatant in targetableCombatants and not (targets == BattleCommand.Targets.ANY or targets == BattleCommand.Targets.ANY_EXCEPT_SELF):
		focusedCombatant = battleUI.commandingCombatant
	for targetableCombatant: CombatantNode in targetableCombatants:
		targetableCombatant.update_select_btn(true, not singleSelect)
		if focusedCombatant == null:
			# if the move is any/any except self targeting: prefer targeting an enemy if the command isn't one that's generally ally-friendly
			# otherwise, target whoever (starting with ally)
			if not ((targets == BattleCommand.Targets.ANY or targets == BattleCommand.Targets.ANY_EXCEPT_SELF) and not anyShouldTargetAlly and targetableCombatant.role == CombatantNode.Role.ALLY):
				focusedCombatant = targetableCombatant
	
	# failsafe in case no combatant was focused; attempt to focus the first in the list
	if focusedCombatant == null and len(targetableCombatants) > 0:
		focusedCombatant = targetableCombatants[0]
	
	if focusedCombatant == null or len(targetableCombatants) == 0:
		initial_focus() # nothing is focusable - means there are no targetable combatants 
	elif len(targetableCombatants) == 1 or not singleSelect:
		# only one option is available - screen is just for confirmation at this point
		confirmButton.grab_focus()
	else:
		focusedCombatant.focus_select_btn() # focus the first combatant to be focusable
	
	battleUI.battleController.update_combatant_focus_neighbors() # reset combatant neighbors then update them below
	
	var nodes: Array[CombatantNode] = battleUI.battleController.get_bottom_most_targetable_combatant_nodes()
	for node in nodes:
		node.set_buttons_bottom_neighbor(backButton)
		node.set_buttons_bottom_neighbor(confirmButton)
	
	var node: CombatantNode = battleUI.battleController.get_top_left_most_targetable_combatant_node()
	if node != null:
		node.set_buttons_top_neighbor(battleUI.battlePanels.questsOpenButton)
		# process stats last so quests can navigate to it too
		node.set_buttons_top_neighbor(battleUI.battlePanels.statsOpenButton)
	
	node = battleUI.battleController.get_top_right_most_targetable_combatant_node()
	if node != null:
		node.set_buttons_top_neighbor(battleUI.battlePanels.flowOfBattle.fobButton)
	
	connect_targetable_combatants_to_each_other(allCombatantNodes, targetableCombatants)
	
	if focusedCombatant != null:
		focusedCombatant.set_selected(true)
	update_targets_listing(true, focusedCombatant)
	update_confirm_btn()

func connect_targetable_combatants_to_each_other(allCombatantNodes: Array[CombatantNode], targetableCombatantNodes: Array[CombatantNode]):
	var combatantsDict: Dictionary[String, CombatantNode] = {}
	
	for combatantNode: CombatantNode in allCombatantNodes:
		combatantsDict[combatantNode.battlePosition] = combatantNode
	
	# MINION COMBATANT
	if combatantsDict['Ally'] in targetableCombatantNodes:
		var targetNode: CombatantNode = null
		var playerCombatantNeighbors: Array[String] = ['Top', 'Center', 'Bottom', 'Ally']
		for neighbor: String in playerCombatantNeighbors:
			if combatantsDict[neighbor] in targetableCombatantNodes:
				targetNode = combatantsDict[neighbor]
				break
		combatantsDict['Ally'].set_focus_right_combatant_node_neighbor(targetNode)
	
	# PLAYER COMBATANT
	if combatantsDict['You'] in targetableCombatantNodes:
		var targetNode: CombatantNode = null
		var playerCombatantNeighbors: Array[String] = ['Center', 'Bottom', 'Top', 'You']
		for neighbor: String in playerCombatantNeighbors:
			if combatantsDict[neighbor] in targetableCombatantNodes:
				targetNode = combatantsDict[neighbor]
				break
		combatantsDict['You'].set_focus_right_combatant_node_neighbor(targetNode)
	
	# BOTTOM ENEMY COMBATANT
	if combatantsDict['Bottom'] in targetableCombatantNodes:
		var targetNode: CombatantNode = null
		var playerCombatantNeighbors: Array[String] = ['You', 'Ally', 'Bottom']
		for neighbor: String in playerCombatantNeighbors:
			if combatantsDict[neighbor] in targetableCombatantNodes:
				targetNode = combatantsDict[neighbor]
				break
		combatantsDict['Bottom'].set_focus_left_combatant_node_neighbor(targetNode)
	
	# TOP ENEMY COMBATANT
	if combatantsDict['Top'] in targetableCombatantNodes:
		var targetNode: CombatantNode = null
		var playerCombatantNeighbors: Array[String] = ['Ally', 'You', 'Top']
		for neighbor: String in playerCombatantNeighbors:
			if combatantsDict[neighbor] in targetableCombatantNodes:
				targetNode = combatantsDict[neighbor]
				break
		combatantsDict['Top'].set_focus_left_combatant_node_neighbor(targetNode)
	
	# CENTER ENEMY COMBATANT
	if combatantsDict['Center'] in targetableCombatantNodes:
		var targetNode: CombatantNode = null
		var playerCombatantNeighbors: Array[String] = ['You', 'Ally', 'Center']
		for neighbor: String in playerCombatantNeighbors:
			if combatantsDict[neighbor] in targetableCombatantNodes:
				targetNode = combatantsDict[neighbor]
				break
		combatantsDict['Center'].set_focus_left_combatant_node_neighbor(targetNode)

# returns true if at least one target is selected
func update_targets_listing(button_pressed: bool = false, combatantNode: CombatantNode = null) -> bool:
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
		return false
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
		return true
	
func update_confirm_btn():
	var confirmDisabled: bool = true
	for combatantNode in battleUI.battleController.get_all_combatant_nodes():
		if combatantNode.is_selected():
			confirmDisabled = false
	confirmButton.disabled = confirmDisabled

func reset_targets(confirming: bool = false):
	for cNode in battleUI.battleController.get_all_combatant_nodes():
		if cNode.is_alive():
			if cNode.toggled.is_connected(_on_combatant_selected):
				cNode.toggled.disconnect(_on_combatant_selected)
			if not confirming or not cNode.is_selected() or referringMenu != BattleState.Menu.SURGE_MOVES:
				# hide all select buttons after this if picking a charge move or if it wasn't selected
				cNode.set_selected(false)
				cNode.update_select_btn(false)
			else:
				cNode.update_select_btn(true, true) # if picking a surge move, disable select btn
				# after submit in surge menu, that menu will update all buttons to be enabled but invisible

func _on_combatant_selected(button_pressed: bool, combatantNode: CombatantNode):
	var atLeastOne: bool = update_targets_listing(button_pressed, combatantNode)
	update_confirm_btn()
	# if "deselecting" the last combatant: actually confirm with this combatant instead
	if not atLeastOne:
		combatantNode.selectCombatantBtn.button_pressed = true
		_on_confirm_button_pressed()

func _on_confirm_button_pressed():
	var targetPositions: Array[String] = []
	for combatantNode in battleUI.battleController.get_all_combatant_nodes():
		if combatantNode.is_selected():
			targetPositions.append(combatantNode.battlePosition)
	battleUI.commandingCombatant.combatant.command.set_targets(targetPositions)
	
	reset_targets(true)
	if battleUI.commandingCombatant.combatant.command.type != BattleCommand.Type.MOVE or \
			battleUI.commandingCombatant.combatant.command.moveEffectType != Move.MoveEffectType.SURGE:
		if moveEffect != null:
			battleUI.commandingCombatant.combatant.command.orbChange = moveEffect.orbChange
		else:
			battleUI.commandingCombatant.combatant.command.orbChange = 0
		battleUI.complete_command()
	else:
		battleUI.set_menu_state(BattleState.Menu.SURGE_SPEND, false)
	
	battleUI.battleController.update_combatant_focus_neighbors()

func _on_back_button_pressed():
	reset_targets(false)
	battleUI.set_menu_state(referringMenu)
