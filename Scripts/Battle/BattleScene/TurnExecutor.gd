extends Node2D
class_name TurnExecutor

enum TurnResult {
	NOTHING = 0,
	PLAYER_WIN = 1,
	ENEMY_WIN = 2,
	ESCAPE = 3,
}

@export var battleController: BattleController
@export var battleUI: BattleUI

var turnQueue: TurnQueue = TurnQueue.new()
var escaping: bool = false
var result: TurnExecutor.TurnResult = TurnExecutor.TurnResult.NOTHING

func start_simulation():
	var combatants: Array[Combatant] = []
	var allCombatantNodes: Array[CombatantNode] = battleController.get_all_combatant_nodes()
	for combatantNode in allCombatantNodes:
		if combatantNode.is_alive():
			if combatantNode.role == CombatantNode.Role.ENEMY:
				combatantNode.get_command(allCombatantNodes)
			combatants.append(combatantNode.combatant)
			combatantNode.combatant.command.get_targets_from_combatant_nodes(allCombatantNodes)
			if combatantNode.combatant.statusEffect != null:
				combatantNode.combatant.statusEffect.apply_status(combatantNode.combatant, StatusEffect.ApplyTiming.BEFORE_ROUND)
	turnQueue = TurnQueue.new(combatants)

func play_turn():
	var allCombatants: Array[CombatantNode] = battleController.get_all_combatant_nodes()
	var combatant: Combatant = turnQueue.peek_next()
	if combatant != null:	
		combatant.command.get_targets_from_combatant_nodes(allCombatants) # make sure to get all commands before applying statuses
		if combatant.statusEffect != null:
			combatant.statusEffect.apply_status(combatant, StatusEffect.ApplyTiming.BEFORE_DMG_CALC)
		escaping = combatant.command.execute_command(combatant, allCombatants) # perform all necessary calculations
		if combatant.statusEffect != null:
			combatant.statusEffect.apply_status(combatant, StatusEffect.ApplyTiming.AFTER_DMG_CALC)
		battleUI.update_hp_tags()
		update_turn_text()
	else:
		battleUI.set_menu_state(BattleState.Menu.POST_ROUND)
	
func update_turn_text() -> bool:
	var allCombatants: Array[CombatantNode] = battleController.get_all_combatant_nodes()
	var text: String = ''
	
	if battleUI.menuState == BattleState.Menu.PRE_BATTLE or battleUI.menuState == BattleState.Menu.PRE_ROUND or battleUI.menuState == BattleState.Menu.POST_ROUND:
		if len(battleController.state.calcdStateStrings) == 0:
			calculate_intermediate_state_strings(allCombatants)
			if len(battleController.state.calcdStateStrings) == 0:
				battleUI.advance_intermediate_state(result)
				return false
			else:
				text = battleController.state.calcdStateStrings[0]
		elif battleController.state.calcdStateIndex < len(battleController.state.calcdStateStrings):
			text = battleController.state.calcdStateStrings[battleController.state.calcdStateIndex]
	
	if battleUI.menuState == BattleState.Menu.RESULTS:
		var combatant: Combatant = turnQueue.peek_next()
		combatant.command.get_targets_from_combatant_nodes(allCombatants)
		text = combatant.command.get_command_results(combatant)
		if combatant.statusEffect != null:
			text += ' ' + combatant.statusEffect.get_status_effect_str(combatant, StatusEffect.ApplyTiming.AFTER_DMG_CALC)
	
	battleUI.results.show_text(text)
	return text != ''

func finish_turn() -> TurnResult:
	var lastCombatant: Combatant = turnQueue.pop() # remove the turn from the queue
	lastCombatant.command = null # remove the command from the previous turn's combatant
	var alliesDown: int = 0
	var enemiesDown: int = 0
	for combatantNode in battleController.get_all_combatant_nodes():
		if combatantNode.combatant != null:
			combatantNode.combatant.update_downed()
		if not combatantNode.is_alive(): # if combatant is not alive (after being updated)
			if combatantNode.role == CombatantNode.Role.ALLY:
				alliesDown += 1 # ally down
			else:
				enemiesDown += 1 # enemy down
	battleUI.update_downed()
	if alliesDown == 2: # all allies are down:
		result = TurnResult.ENEMY_WIN
		return result
	if enemiesDown == 3: # all enemies are down:
		result = TurnResult.PLAYER_WIN
		return result
	if escaping: # if escaping
		turnQueue.empty() # end the round immediately
		result = TurnResult.ESCAPE
		return result
	play_turn() # go to the next turn	
	result = TurnResult.NOTHING
	return result

func calculate_intermediate_state_strings(allCombatantNodes: Array[CombatantNode]):
	battleController.state.calcdStateStrings = []
	for combatantNode in allCombatantNodes:
		if combatantNode.is_alive():
			if battleUI.menuState == BattleState.Menu.PRE_BATTLE:
				pass # TODO generate pre-battle texts (equipment only)
			
			if battleUI.menuState == BattleState.Menu.PRE_ROUND or battleUI.menuState == BattleState.Menu.POST_ROUND:
				var timing: StatusEffect.ApplyTiming = StatusEffect.ApplyTiming.BEFORE_ROUND if battleUI.menuState == BattleState.Menu.PRE_ROUND else StatusEffect.ApplyTiming.AFTER_ROUND
				var statusEffectString: String = ''
				if combatantNode.combatant.statusEffect != null:
					statusEffectString = combatantNode.combatant.statusEffect.get_status_effect_str(combatantNode.combatant, timing)
				# TODO generate equipment pre/post round effect strings
				if statusEffectString != '':
					battleController.state.calcdStateStrings.append(statusEffectString)

func advance_precalcd_text() -> bool:
	battleController.state.calcdStateIndex += 1
	update_turn_text()
	return battleController.state.calcdStateIndex >= len(battleController.state.calcdStateStrings)
