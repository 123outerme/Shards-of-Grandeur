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
	play_turn() # start the first turn

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
		battleUI.round_complete()
	
func update_turn_text():
	var allCombatants: Array[CombatantNode] = battleController.get_all_combatant_nodes()
	var combatant: Combatant = turnQueue.peek_next()
	combatant.command.get_targets_from_combatant_nodes(allCombatants)
	var text: String = combatant.command.get_command_results(combatant)
	if combatant.statusEffect != null:
		text += ' ' + combatant.statusEffect.get_status_effect_str(combatant, StatusEffect.ApplyTiming.AFTER_DMG_CALC)
	battleUI.results.show_text(text)

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
	if alliesDown == 2: # all allies are down:
		return TurnResult.ENEMY_WIN
	if enemiesDown == 3: # all enemies are down:
		return TurnResult.PLAYER_WIN
	battleUI.update_downed()
	play_turn() # go to the next turn
	if escaping: # if escaping
		turnQueue.empty() # end the round immediately
		return TurnResult.ESCAPE
	return TurnResult.NOTHING
