extends BattleTester

const TEST_DIR: String = 'res://test/'

func _ready():
	battleUI = get_node('MockBattleUI')
	battleAnimationManager = get_node('BattleAnimationManager')
	SceneLoader.audioHandler = get_node('MockAudioHandler')
	PlayerResources.playerInfo = PlayerInfo.new()
	PlayerResources.playerInfo.encounter = encounter
	# enable the battle text to show whether a move was charged or surged 
	PlayerResources.questInventory.currentAct = 1
	PlayerResources.playerInfo.set_dialogue_seen('grandstone_dr_ildran', 'surge')
	SettingsHandler.gameSettings = GameSettings.new()
	SettingsHandler.gameSettings.battleAnims = false
	nextButton.visible = false
	
	if not DirAccess.dir_exists_absolute(TEST_DIR):
		DirAccess.make_dir_recursive_absolute(TEST_DIR)
		
	if not FileAccess.file_exists(TEST_DIR + '.gdignore'):
		var gdIgnoreFile = FileAccess.open(TEST_DIR + '.gdignore', FileAccess.WRITE)
		gdIgnoreFile.close()
	
	var subdir: String = 'battle/'
	if not DirAccess.dir_exists_absolute(TEST_DIR + subdir):
		DirAccess.make_dir_recursive_absolute(TEST_DIR + subdir)
	
	var combatants: Array[Combatant] = [_playerCombatant, encounter.autoAlly, encounter.combatant1, encounter.combatant2, encounter.combatant3]
	var combatantLvs: Array[int] = [playerLv, encounter.autoAllyLevel, encounter.combatant1Level, encounter.combatant2Level, encounter.combatant3Level]
	#var combatantCommands: Array[BattleCommand] = [playerCommand, minionCommand, enemy1Command, enemy2Command, enemy3Command]
	var combatantAis: Array[CombatantAi] = [playerAi, null, null, null, null]
	if encounter is StaticEncounter:
		combatantAis[2] = encounter.combatant1Ai
		combatantAis[3] = encounter.combatant2Ai
		combatantAis[4] = encounter.combatant3Ai
	var combatantStatuses: Array[StatusEffect] = [playerStatus, minionStatus, enemy1Status, enemy2Status, enemy3Status]
	var combatantRunes: Array = [playerRunes, minionRunes, enemy1Runes, enemy2Runes, enemy3Runes]
	var combatantRuneCasters: Array = [playerRuneCasterPositions, minionRuneCasterPositions, enemy1RuneCasterPositions, enemy2RuneCasterPositions, enemy3RuneCasterPositions]
	var currentHps: Array[int] = [currentPlayerHp, -1, -1, -1, -1]
	for idx in range(len(combatants)):
		var combatant: Combatant = combatants[idx]
		if combatant != null:
			combatant = combatant.copy()
			if combatant.get_evolution() != null:
				combatant.switch_evolution(combatant.get_evolution(), null)
			if combatantLvs[idx] > combatant.stats.level:
				combatant.level_up_nonplayer(combatantLvs[idx])
			if combatant == _playerCombatant:
				if playerStatAllocStrat != null:
					playerStatAllocStrat.allocate_stats(combatant.stats)
			if len(combatant.stats.moves) == 0:
				combatant.assign_moves_nonplayer()
			for move: Move in combatant.stats.moves:
				print(combatant.disp_name(), ': ', move.moveName)
			if currentHps[idx] == -1:
				combatant.currentHp = combatant.stats.maxHp
			else:
				combatant.currentHp = currentHps[idx]
			if combatant.statChanges == null:
				combatant.statChanges = StatChanges.new()
			#combatant.command = combatantCommands[idx]
			combatant.statusEffect = combatantStatuses[idx]
			combatant.runes = combatantRunes[idx]
			if combatantAis[idx] == null:
				combatantAis[idx] = combatant.get_ai()
		if combatantAis[idx] != null:
			get_all_combatant_nodes()[idx].battleAi = combatantAis[idx].copy()
		get_all_combatant_nodes()[idx].combatant = combatant
		get_all_combatant_nodes()[idx].load_combatant_node()
	
	for idx: int in range(len(get_all_combatant_nodes())):
		if get_all_combatant_nodes()[idx].combatant != null:
			for runeIdx: int in range(len(combatantRuneCasters[idx])):
				var caster: Combatant = null
				for cNode: CombatantNode in get_all_combatant_nodes():
					if cNode.battlePosition == combatantRuneCasters[idx][runeIdx]:
						caster = cNode.combatant
				get_all_combatant_nodes()[idx].combatant.runes[runeIdx].caster = caster
	
	state = BattleState.new()
	state.menu = BattleState.Menu.PRE_ROUND
	battleUI.menuState = BattleState.Menu.PRE_ROUND
	
	state.calcdStateIndex = 0
	var result: WinCon.TurnResult = WinCon.TurnResult.NOTHING
	while result == WinCon.TurnResult.NOTHING:
		battleUI.results.show_text('Turn ' + String.num(state.turnNumber) + ' START:')
		for combatantNode: CombatantNode in get_all_combatant_nodes():
			if combatantNode.combatant != null and combatantNode.is_alive() and combatantNode.role == CombatantNode.Role.ALLY:
				combatantNode.get_command(get_all_combatant_nodes(), state)
		turnExecutor.start_simulation()
		turnExecutor.update_turn_text()
		while state.calcdStateIndex < len(state.calcdStateStrings):
			turnExecutor.update_turn_text()
			state.calcdStateIndex += 1
		
		if battleUI.menuState != BattleState.Menu.RESULTS:
			battleUI.menuState = BattleState.Menu.RESULTS
			turnExecutor.play_turn()
		while turnExecutor.turnQueue.peek_next() != null:
			turnExecutor.finish_turn()
		
		reset_intermediate_state_strs()
		turnExecutor.update_turn_text()
		while not turnExecutor.advance_precalcd_text():
			pass # advance precalcd text
		result = PlayerResources.playerInfo.encounter.get_win_con_result(get_all_combatant_nodes(), state)
		for combatantNode: CombatantNode in get_all_combatant_nodes():
			if combatantNode.combatant != null:
				battleUI.results.show_text('End of Turn ' +
					combatantNode.combatant.disp_name() + ' (' + combatantNode.battlePosition +
					') HP: ' + String.num(combatantNode.combatant.currentHp) + ' / ' +
					String.num(combatantNode.combatant.stats.maxHp)
				)
		
		state.turnNumber += 1
		
	var battleText: String = ''
	for text: String in battleUI.results.resultsLines:
		battleText += text + '\n'
	
	var filename: String = 'battle.txt'
	
	var file = FileAccess.open(TEST_DIR + subdir + filename, FileAccess.WRITE)
	if file != null:
		file.store_string(battleText)
		if file.get_error() != OK:
			printerr('FileAccess error writing CSV content to file ', TEST_DIR + filename, ' (error ', file.get_error(), ')')
		file.close()
	else:
		if FileAccess.get_open_error() != OK:
			printerr('FileAccess error opening file ', TEST_DIR + filename, ' (error ', FileAccess.get_open_error(), ')')
