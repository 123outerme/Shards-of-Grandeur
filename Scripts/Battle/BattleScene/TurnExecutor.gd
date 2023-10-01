extends Node2D
class_name TurnExecutor

@export var battleController: BattleController
@export var battleUI: BattleUI
var turnQueue: TurnQueue = TurnQueue.new()

func start_simulation():
	var combatants: Array[Combatant] = []
	for node in battleController.combatantNodes:
		var combatantNode = node as CombatantNode
		if combatantNode.combatant != null:
			if combatantNode.combatant.command == null:
				combatantNode.combatant.command = BattleCommand.new()
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

func finish_turn():
	turnQueue.pop() # remove the turn from the queue
	play_turn() # go to the next turn
