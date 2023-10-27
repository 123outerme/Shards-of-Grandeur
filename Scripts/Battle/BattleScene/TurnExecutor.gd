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
			# apply before-round effects
			if combatantNode.combatant.statusEffect != null:
				combatantNode.combatant.statusEffect.apply_status(combatantNode.combatant, BattleCommand.ApplyTiming.BEFORE_ROUND)
			if combatantNode.combatant.stats.equippedWeapon != null:
				combatantNode.combatant.stats.equippedWeapon.apply_effects(combatantNode.combatant, BattleCommand.ApplyTiming.BEFORE_ROUND)
			if combatantNode.combatant.stats.equippedArmor != null:
				combatantNode.combatant.stats.equippedArmor.apply_effects(combatantNode.combatant, BattleCommand.ApplyTiming.BEFORE_ROUND)
	turnQueue = TurnQueue.new(combatants)

func play_turn():
	var allCombatants: Array[CombatantNode] = battleController.get_all_combatant_nodes()
	var combatant: Combatant = turnQueue.peek_next()
	if combatant != null: # apply before-damage-calc status
		combatant.command.get_targets_from_combatant_nodes(allCombatants) # make sure to get all commands before applying statuses
		if combatant.statusEffect != null:
			combatant.statusEffect.apply_status(combatant, BattleCommand.ApplyTiming.BEFORE_DMG_CALC)
		escaping = combatant.command.execute_command(combatant, allCombatants) # perform all necessary calculations
		if combatant.statusEffect != null: # apply after-damage-calc status
			combatant.statusEffect.apply_status(combatant, BattleCommand.ApplyTiming.AFTER_DMG_CALC)
		update_turn_text()
	else:
		for combatantNode in battleController.get_all_combatant_nodes(): # apply after-round effects
			if combatantNode.is_alive():
				if combatantNode.combatant.statusEffect != null:
					combatantNode.combatant.statusEffect.apply_status(combatantNode.combatant, BattleCommand.ApplyTiming.AFTER_ROUND)
				if combatantNode.combatant.stats.equippedWeapon != null:
					combatantNode.combatant.stats.equippedWeapon.apply_effects(combatantNode.combatant, BattleCommand.ApplyTiming.AFTER_ROUND)
				if combatantNode.combatant.stats.equippedArmor != null:
					combatantNode.combatant.stats.equippedArmor.apply_effects(combatantNode.combatant, BattleCommand.ApplyTiming.AFTER_ROUND)
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
		if combatant != null:
			combatant.command.get_targets_from_combatant_nodes(allCombatants)
			text = combatant.command.get_command_results(combatant)
			if combatant.statusEffect != null:
				text += ' ' + combatant.statusEffect.get_status_effect_str(combatant, BattleCommand.ApplyTiming.AFTER_DMG_CALC)
	
	battleUI.results.show_text(text)
	return text != ''

func finish_turn() -> TurnResult:
	var lastCombatant: Combatant = turnQueue.pop() # remove the turn from the queue
	lastCombatant.command = null # remove the command from the previous turn's combatant
	result = check_battle_end_conditions()
	if result == TurnResult.NOTHING:
		play_turn() # go to the next turn
	return result

func check_battle_end_conditions() -> TurnResult:
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
		return TurnResult.ENEMY_WIN
	if enemiesDown == 3: # all enemies are down:
		return TurnResult.PLAYER_WIN
	if escaping: # if escaping
		turnQueue.empty() # end the round immediately
		return TurnResult.ESCAPE
	return TurnResult.NOTHING

func calculate_intermediate_state_strings(allCombatantNodes: Array[CombatantNode]):
	battleController.state.calcdStateStrings = []
	for combatantNode in allCombatantNodes:
		if combatantNode.is_alive():
			if battleUI.menuState == BattleState.Menu.PRE_BATTLE:
				var equippedWeaponText: String = ''
				var equippedArmorText: String = ''
				if combatantNode.combatant.stats.equippedWeapon != null:
					equippedWeaponText = combatantNode.combatant.stats.equippedWeapon.get_apply_text(combatantNode.combatant, BattleCommand.ApplyTiming.BEFORE_BATTLE)
				if combatantNode.combatant.stats.equippedArmor != null:
					equippedArmorText = combatantNode.combatant.stats.equippedArmor.get_apply_text(combatantNode.combatant, BattleCommand.ApplyTiming.BEFORE_BATTLE)
				if equippedWeaponText != '' or equippedArmorText != '':
					if equippedWeaponText != '' and equippedArmorText != '':
						equippedWeaponText += ' '
					battleController.state.calcdStateStrings.append(equippedWeaponText + equippedArmorText)
			
			if battleUI.menuState == BattleState.Menu.PRE_ROUND or battleUI.menuState == BattleState.Menu.POST_ROUND:
				var timing: BattleCommand.ApplyTiming = BattleCommand.ApplyTiming.BEFORE_ROUND if battleUI.menuState == BattleState.Menu.PRE_ROUND else BattleCommand.ApplyTiming.AFTER_ROUND
				var statusEffectString: String = ''
				if combatantNode.combatant.statusEffect != null:
					statusEffectString = combatantNode.combatant.statusEffect.get_status_effect_str(combatantNode.combatant, timing)
				
				var equippedWeaponText: String = ''
				var equippedArmorText: String = ''
				
				if combatantNode.combatant.stats.equippedWeapon != null:
					equippedWeaponText = combatantNode.combatant.stats.equippedWeapon.get_apply_text(combatantNode.combatant, timing)
				if combatantNode.combatant.stats.equippedArmor != null:
					equippedArmorText = combatantNode.combatant.stats.equippedArmor.get_apply_text(combatantNode.combatant, timing)
				if equippedWeaponText != '' or equippedArmorText != '':
					if equippedWeaponText != '' and equippedArmorText != '':
						equippedWeaponText += ' '
					if statusEffectString != '':
						statusEffectString += ' '
					statusEffectString += equippedWeaponText + equippedArmorText
				if statusEffectString != '':
					battleController.state.calcdStateStrings.append(statusEffectString)

func advance_precalcd_text() -> bool:
	battleController.state.calcdStateIndex += 1
	update_turn_text()
	return battleController.state.calcdStateIndex >= len(battleController.state.calcdStateStrings)
