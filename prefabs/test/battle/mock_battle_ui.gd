extends BattleUI

class MockResults extends Results:
	func _init():
		pass
	
	func tween_started():
		pass
	
	func show_text(text: String):
		print('Results screen shows text:\n', text)

static func state_to_string(state: BattleState.Menu) -> String:
	match state:
		BattleState.Menu.SUMMON:
			return 'Summon'
		BattleState.Menu.PRE_BATTLE:
			return 'Pre-Battle'
		BattleState.Menu.ALL_COMMANDS:
			return 'All Commands'
		BattleState.Menu.MOVES:
			return 'Select Move'
		BattleState.Menu.ITEMS:
			return 'Select Item'
		BattleState.Menu.PICK_TARGETS:
			return 'Pick Targets'
		BattleState.Menu.PRE_ROUND:
			return 'Before Battle Round'
		BattleState.Menu.RESULTS:
			return 'Turn Results'
		BattleState.Menu.POST_ROUND:
			return 'After Battle Round'
		BattleState.Menu.BATTLE_COMPLETE:
			return 'Battle Complete'
		BattleState.Menu.LEVEL_UP:
			return 'Level Up!'
	return 'ERROR'

func _ready():
	results = MockResults.new() as Results

func set_menu_state(state: BattleState.Menu, _savPrevState = false):
	menuState = state
	print('set menu state: ', state_to_string(state))

func advance_intermediate_state(result: TurnExecutor.TurnResult = TurnExecutor.TurnResult.NOTHING):
	if menuState == BattleState.Menu.PRE_BATTLE or menuState == BattleState.Menu.PRE_ROUND or menuState == BattleState.Menu.POST_ROUND:
		var newMenuState: BattleState.Menu = BattleState.Menu.ALL_COMMANDS # default: advance from PRE_BATTLE to ALL_COMMANDS
		if menuState == BattleState.Menu.PRE_ROUND:
			set_menu_state(BattleState.Menu.RESULTS) # prevent recursion by just setting here
			battleController.turnExecutor.play_turn() # start the first turn
			return
		if menuState == BattleState.Menu.POST_ROUND:
			if result == TurnExecutor.TurnResult.NOTHING: # check again before completing round
				result = battleController.turnExecutor.check_battle_end_conditions()
			if result != TurnExecutor.TurnResult.NOTHING:
				newMenuState = BattleState.Menu.BATTLE_COMPLETE
			else:
				round_complete()
				return

func update_downed():
	for combatantNode in battleController.get_all_combatant_nodes():
		if combatantNode.combatant != null:
			combatantNode.combatant.update_downed()
			var combatantName: String = combatantNode.combatant.disp_name() + ' (' + combatantNode.battlePosition + ')'
			if not combatantNode.is_alive():
				print(combatantName, ' was downed!')
			else:
				print(combatantName, ' has HP: ',
					String.num(combatantNode.combatant.currentHp), ' / ',
					String.num(combatantNode.combatant.stats.maxHp))
		combatantNode.visible = combatantNode.is_alive()

func round_complete():
	print('Round complete!')
