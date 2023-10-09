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
	var allCombatantNodes: Array[CombatantNode] = []
	for node in battleController.combatantNodes:
		var combatantNode: CombatantNode = node as CombatantNode
		allCombatantNodes.append(combatantNode)
	for combatantNode in allCombatantNodes:
		if combatantNode.is_alive():
			if combatantNode.role == CombatantNode.Role.ENEMY:
				combatantNode.get_command(allCombatantNodes)
			combatants.append(combatantNode.combatant)
	turnQueue = TurnQueue.new(combatants)
	play_turn() # start the first turn

func play_turn():
	var allCombatants: Array[CombatantNode] = []
	for node in battleUI.battleController.combatantNodes:
		var combatantNode: CombatantNode = node as CombatantNode
		allCombatants.append(combatantNode)
	var combatant: Combatant = turnQueue.peek_next()
	if combatant != null:
		escaping = combatant.command.execute_command(combatant, allCombatants) # perform all necessary calculations
		battleUI.update_hp_tags()
		update_turn_text()
	else:
		battleUI.round_complete()
	
func update_turn_text():
	var allCombatants: Array[CombatantNode] = []
	for node in battleUI.battleController.combatantNodes:
		var combatantNode: CombatantNode = node as CombatantNode
		allCombatants.append(combatantNode)
	var combatant: Combatant = turnQueue.peek_next()
	combatant.command.get_targets_from_combatant_nodes(allCombatants)
	battleUI.results.show_text(combatant.command.get_command_results(combatant))

func finish_turn() -> TurnResult:
	var lastCombatant: Combatant = turnQueue.pop() # remove the turn from the queue
	lastCombatant.command = null # remove the command from the previous turn's combatant
	var alliesDown: int = 0
	var enemiesDown: int = 0
	for node in battleController.combatantNodes:
		var combatantNode: CombatantNode = node as CombatantNode
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
