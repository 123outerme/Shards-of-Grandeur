extends Node2D
class_name TurnExecutor

enum TurnResult {
	NOTHING = 0,
	PLAYER_WIN = 1,
	ENEMY_WIN = 2
}

@export var battleController: BattleController
@export var battleUI: BattleUI
var turnQueue: TurnQueue = TurnQueue.new()

func start_simulation():
	var combatants: Array[Combatant] = []
	for node in battleController.combatantNodes:
		var combatantNode: CombatantNode = node as CombatantNode
		if combatantNode.is_alive():
			if combatantNode.role == CombatantNode.Role.ENEMY:
				combatantNode.get_command(battleController.combatantNodes)
			combatants.append(combatantNode.combatant)
	turnQueue = TurnQueue.new(combatants)
	play_turn() # start the first turn

func play_turn():
	var combatant: Combatant = turnQueue.peek_next()
	if combatant != null:
		combatant.command.execute_command(combatant) # perform all necessary calculations
		battleUI.update_hp_tags()
		update_turn_text()
	else:
		battleUI.round_complete()
	
func update_turn_text():
	var combatant: Combatant = turnQueue.peek_next()
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
	play_turn() # go to the next turn
	return TurnResult.NOTHING
