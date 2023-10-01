extends Node2D
class_name TurnExecutor

@export var battleController: BattleController
@export var battleUI: BattleUI
var turnQueue: TurnQueue = TurnQueue.new()

func start_simulation():
	var combatants: Array[Combatant] = []
	for node in battleController.combatantNodes:
		var combatantNode = node as CombatantNode
		combatants.append(combatantNode.combatant)

func play_turn():
	var combatant: Combatant = turnQueue.peek_next()
	if combatant != null:
		update_turn_text(combatant)
	else:
		battleUI.round_complete()
	
func update_turn_text(combatant: Combatant):
	battleUI.results.show_text(combatant.command.get_command_results(combatant))

func resolve_turn():
	var combatant: Combatant = turnQueue.peek_next()

func finish_turn():
	turnQueue.pop() # remove the turn from the queue
	play_turn()
