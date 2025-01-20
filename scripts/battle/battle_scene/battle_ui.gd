extends Camera2D
class_name BattleUI

@export var menuState: BattleState.Menu = BattleState.Menu.SUMMON
@export var commandingMinion: bool = false
@export var battleController: BattleController

var commandingCombatant: CombatantNode = null
var prevMenu: BattleState.Menu = BattleState.Menu.SUMMON
var playerWins: bool = false
var escapes: bool = false
var checkingSummonStats: bool = false

var previousFocus: Control = null

@onready var summonMenu: SummonMenu = get_node_or_null("BattleTextBox/TextContainer/MarginContainer/Summon")
@onready var allCommands: AllCommands = get_node_or_null("BattleTextBox/TextContainer/MarginContainer/AllCommands")
@onready var moves: MovesMenu = get_node_or_null("BattleTextBox/TextContainer/MarginContainer/Moves")
@onready var targets: TargetsMenu = get_node_or_null("BattleTextBox/TextContainer/MarginContainer/Targets")
@onready var surge: SurgeMenu = get_node_or_null('BattleTextBox/TextContainer/MarginContainer/Surge')
@onready var results: Results = get_node_or_null("BattleTextBox/TextContainer/MarginContainer/Results")
@onready var battleComplete: BattleCompleteMenu = get_node_or_null("BattleTextBox/TextContainer/MarginContainer/BattleComplete")
@onready var customWinText: CustomWinTextPanel = get_node_or_null("UIPanels/CustomWinTextPanel")

@onready var battlePanels: BattlePanels = get_node_or_null("UIPanels")
@onready var summonMinionPanel: SummonMinionPanel = get_node_or_null("UIPanels/SummonMinionPanel")
@onready var inventoryPanel: InventoryMenu = get_node_or_null("UIPanels/InventoryPanelNode")
@onready var statsPanel: StatsMenu = get_node_or_null("UIPanels/StatsPanelNode")

func _ready():
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	
func set_menu_state(newState: BattleState.Menu, savePrevState: bool = true):
	if savePrevState:
		prevMenu = menuState
	menuState = newState
	battleController.state.menu = newState
	commandingCombatant = battleController.minionCombatant if commandingMinion else battleController.playerCombatant
	apply_menu_state()

func apply_menu_state():
	summonMenu.visible = menuState == BattleState.Menu.SUMMON
	if summonMenu.visible:
		summonMenu.initial_focus()
		battlePanels.flowOfBattle.connect_fob_focus_button_to(summonMenu.yesSummonBtn)
		battlePanels.connect_top_left_panel_buttons_bottom_neighbor(summonMenu.noSummonBtn)
	
	if prevMenu == BattleState.Menu.SUMMON: # if PREVIOUS menu was summoning, reset the filter
		inventoryPanel.selectedFilter = Item.Type.ALL
	
	allCommands.visible = menuState == BattleState.Menu.ALL_COMMANDS or menuState == BattleState.Menu.ITEMS
	if allCommands.visible:
		allCommands.commandingMinion = commandingMinion
		allCommands.commandingCombatant = commandingCombatant
		battlePanels.flowOfBattle.connect_fob_focus_button_to(allCommands.inventoryBtn)
		battlePanels.connect_top_left_panel_buttons_bottom_neighbor(allCommands.chargeMovesBtn)
		allCommands.load_all_commands()
	if menuState == BattleState.Menu.ITEMS:
		open_inventory(false)
	
	moves.visible = menuState == BattleState.Menu.CHARGE_MOVES or menuState == BattleState.Menu.SURGE_MOVES
	if moves.visible:
		battleController.state.moveEffectType = Move.MoveEffectType.CHARGE if menuState == BattleState.Menu.CHARGE_MOVES else Move.MoveEffectType.SURGE
		moves.load_moves()
		battlePanels.flowOfBattle.connect_fob_focus_button_to(moves.get_node('Move2InfoButton'))
		battlePanels.connect_top_left_panel_buttons_bottom_neighbor(moves.get_node('Move1InfoButton'))
		battlePanels.flowOfBattle.connect_fob_focus_button_to(moves.get_node('MoveButton2'))
		battlePanels.connect_top_left_panel_buttons_bottom_neighbor(moves.get_node('MoveButton1'))

	targets.visible = menuState == BattleState.Menu.PICK_TARGETS
	if targets.visible:
		targets.referringMenu = prevMenu
		targets.load_targets()

	surge.visible = menuState == BattleState.Menu.SURGE_SPEND
	if surge.visible:
		surge.load_surge()
		# connect these first so the flow of battle button takes precedence
		battlePanels.connect_top_left_panel_buttons_bottom_neighbor(surge.orbControl)
		battlePanels.flowOfBattle.connect_fob_focus_button_to(surge.orbControl)
	else:
		surge.orbControl.focused = false

	results.visible = menuState == BattleState.Menu.RESULTS \
			or menuState == BattleState.Menu.PRE_BATTLE or menuState == BattleState.Menu.PRE_ROUND \
			or menuState == BattleState.Menu.POST_ROUND
	if results.visible:
		# toggle the Flow of Battle button based on if the battle is starting/round is starting or ending
		battlePanels.flowOfBattle.set_fob_button_enabled(menuState == BattleState.Menu.PRE_BATTLE or menuState == BattleState.Menu.POST_ROUND)
		results.initial_focus()
		results.ignoreOkPressed = false
		results.animFinished = false
		# connect these first so the flow of battle button takes precedence
		battlePanels.connect_top_left_panel_buttons_bottom_neighbor(results.textBoxText)
		battlePanels.flowOfBattle.connect_fob_focus_button_to(results.textBoxText)
		battleController.reset_intermediate_state_strs()
		battleController.turnExecutor.update_turn_text()
		return # returns specifically here because of skipping post-round text
		
	battleComplete.visible = menuState == BattleState.Menu.BATTLE_COMPLETE
	if battleComplete.visible:
		if menuState == BattleState.Menu.POST_ROUND:
			menuState = BattleState.Menu.BATTLE_COMPLETE
		battleComplete.playerWins = playerWins
		battleComplete.playerEscapes = escapes
		# connect these first so the flow of battle button takes precedence
		battlePanels.connect_top_left_panel_buttons_bottom_neighbor(battleComplete.okBtn)
		battlePanels.flowOfBattle.connect_fob_focus_button_to(battleComplete.okBtn)
		
		var rewards: Array[Reward] = build_rewards()
		if len(rewards) > 0:
			battleComplete.rewards = rewards
			battleController.state.rewards = rewards
		else:
			battleComplete.rewards = battleController.state.rewards
	
		# all rewards now obtained
		for combatantNode in battleController.get_all_combatant_nodes():
			if combatantNode.combatant != null and not combatantNode.is_alive() and combatantNode.role == CombatantNode.Role.ENEMY:
				PlayerResources.questInventory.progress_quest(combatantNode.combatant.save_name(), QuestStep.Type.DEFEAT)
				if combatantNode.combatant.get_evolution() != null:
					PlayerResources.questInventory.progress_quest(combatantNode.combatant.get_evolution_save_name(), QuestStep.Type.DEFEAT)
		
		if playerWins and PlayerResources.playerInfo.encounter is StaticEncounter:
			var staticEncounter: StaticEncounter = PlayerResources.playerInfo.encounter as StaticEncounter
			PlayerResources.playerInfo.set_special_battle_completed(staticEncounter.specialBattleId)
		battleComplete.load_battle_over_menu()
	
	if menuState == BattleState.Menu.LEVEL_UP:
		open_stats(PlayerResources.playerInfo.combatant, true)

func advance_intermediate_state(result: WinCon.TurnResult = WinCon.TurnResult.NOTHING):
	if menuState == BattleState.Menu.PRE_BATTLE or menuState == BattleState.Menu.PRE_ROUND or menuState == BattleState.Menu.POST_ROUND:
		var newMenuState: BattleState.Menu = BattleState.Menu.ALL_COMMANDS # default: advance from PRE_BATTLE to ALL_COMMANDS
		if menuState == BattleState.Menu.PRE_ROUND:
			set_menu_state(BattleState.Menu.RESULTS) # prevent recursion by just setting here
			battleController.turnExecutor.play_turn() # start the first turn
			return
		if menuState == BattleState.Menu.POST_ROUND:
			var allCombatants: Array[Combatant] = []
			for combatantNode in battleController.get_all_combatant_nodes(): # gather array of all combatants
				if combatantNode.combatant != null:
					allCombatants.append(combatantNode.combatant)
			for combatantNode in battleController.get_all_combatant_nodes(): # apply after-round effects
				if combatantNode.is_alive() and combatantNode.combatant.statusEffect != null:
					var statusEffect: StatusEffect = combatantNode.combatant.statusEffect
					combatantNode.combatant.statusEffect.apply_status(combatantNode.combatant, allCombatants, BattleCommand.ApplyTiming.AFTER_POST_ROUND)
					if combatantNode.combatant.statusEffect == null:
						battleController.battleAnimationManager.play_combatant_event_text(combatantNode, statusEffect.get_status_type_string() + ' Wore Off', combatantNode.change_current_status.bind(null))
						combatantNode.update_hp_tag() # status effect just got cleared, update HP tag
				combatantNode.update_current_tag_stats(true)
			if result == WinCon.TurnResult.NOTHING: # check again before completing round
				result = battleController.turnExecutor.check_battle_end_conditions()
			if result != WinCon.TurnResult.NOTHING:
				newMenuState = BattleState.Menu.BATTLE_COMPLETE
				playerWins = result == WinCon.TurnResult.PLAYER_WIN
				escapes = result == WinCon.TurnResult.ESCAPE
			else:
				round_complete()
				return
		set_menu_state(newMenuState)
		initial_focus()

func start_pre_battle():
	for combatantNode in battleController.get_all_combatant_nodes():
		# apply pre-battle effects
		if combatantNode.is_alive():
			if combatantNode.combatant.stats.equippedWeapon != null:
				combatantNode.combatant.stats.equippedWeapon.apply_effects(combatantNode.combatant, BattleCommand.ApplyTiming.BEFORE_BATTLE)
			if combatantNode.combatant.stats.equippedArmor != null:
				combatantNode.combatant.stats.equippedArmor.apply_effects(combatantNode.combatant, BattleCommand.ApplyTiming.BEFORE_BATTLE)
	set_menu_state(BattleState.Menu.PRE_BATTLE)
	initial_focus()

func return_to_player_command():
	commandingMinion = battleController.minionCombatant.is_alive() and not battleController.playerCombatant.is_alive()
	commandingCombatant = battleController.minionCombatant if commandingMinion else battleController.playerCombatant
	inventoryPanel.slotQueuedForBattleUse = null
	set_menu_state(BattleState.Menu.ALL_COMMANDS)

func complete_command():
	if not commandingMinion and battleController.minionCombatant.is_alive():
		commandingMinion = true
		set_menu_state(BattleState.Menu.ALL_COMMANDS)
	else:
		battleController.turnExecutor.start_simulation()
		set_menu_state(BattleState.Menu.PRE_ROUND)

func update_hp_tags():
	for combatantNode in battleController.get_all_combatant_nodes():
		combatantNode.update_hp_tag()
	battleController.update_combatant_focus_neighbors()

func update_downed():
	for combatantNode in battleController.get_all_combatant_nodes():
		if combatantNode.combatant != null:
			combatantNode.combatant.update_downed()
		combatantNode.update_hp_tag()
	battleController.update_combatant_focus_neighbors()

func round_complete():
	battleController.state.turnNumber += 1
	battlePanels.set_turn_counter(battleController.state.turnNumber, PlayerResources.playerInfo.encounter.winCon)
	battlePanels.flowOfBattle.set_fob_button_enabled()
	return_to_player_command()

func end_battle():
	battleController.end_battle()

func initial_focus():
	if summonMenu.visible:
		summonMenu.initial_focus()
	if allCommands.visible:
		allCommands.initial_focus()
	if moves.visible:
		moves.initial_focus()
	if targets.visible:
		targets.initial_focus()
	if surge.visible:
		surge.initial_focus()
	if results.visible:
		results.initial_focus()
	if battleComplete.visible:
		battleComplete.okBtn.grab_focus()

func restore_focus():
	if summonMinionPanel.visible and summonMinionPanel.statsShowMinion != null:
		summonMinionPanel.initial_focus()
		return
	
	if previousFocus == null:
		initial_focus()
	else:
		previousFocus.grab_focus()

func open_inventory(forSummon: bool):
	if not forSummon:
		inventoryPanel.summoning = false
		inventoryPanel.lockFilters = false
		inventoryPanel.selectedFilter = Item.Type.HEALING
		if commandingMinion and battleController.playerCombatant.is_alive():
			inventoryPanel.slotQueuedForBattleUse = battleController.playerCombatant.combatant.command.slot
		inventoryPanel.toggle()
	else:
		summonMinionPanel.load_summon_minion_panel()
	battlePanels.animatedBgPanel.visible = true

func _on_inventory_panel_node_item_used(slot: InventorySlot):
	if menuState == BattleState.Menu.SUMMON:
		PlayerResources.inventory.trash_item(slot)
		var shard = slot.item as Shard
		battleController.summon_minion(shard.combatantSaveName, shard)
		start_pre_battle()
	if menuState == BattleState.Menu.ITEMS:
		commandingCombatant.combatant.command = \
				BattleCommand.new(BattleCommand.Type.USE_ITEM, null, Move.MoveEffectType.NONE, 0, slot, [])
		set_menu_state(BattleState.Menu.PICK_TARGETS)
	battlePanels.animatedBgPanel.visible = false
	inventoryPanel.toggle()

func open_stats(combatant: Combatant, levelUp: bool = false):
	if levelUp:
		update_hp_tags()
	
	statsPanel.levelUp = levelUp
	statsPanel.newLvs = battleComplete.gainedLevels
	statsPanel.stats = combatant.stats
	statsPanel.curHp = combatant.currentHp
	statsPanel.readOnly = not levelUp
	statsPanel.visible = false # force it to be turned on
	statsPanel.isPlayer = combatant == PlayerResources.playerInfo.combatant or combatant == battleController.playerCombatant.combatant
	statsPanel.toggle()
	battlePanels.animatedBgPanel.visible = true

func build_rewards() -> Array[Reward]:
	var rewards: Array[Reward] = []
	if escapes and not playerWins:
		return [null]
	# if rewards have not been built yet: do this now
	if len(battleController.state.rewards) == 0:
		var itemsModifier: float = PlayerResources.playerInfo.get_battle_reward_item_count_modifier()
		var expModifier: float = PlayerResources.playerInfo.get_battle_reward_exp_modifier()
		var goldModifier: float = PlayerResources.playerInfo.get_battle_reward_gold_modifier()
		
		if PlayerResources.playerInfo.encounter is StaticEncounter and (PlayerResources.playerInfo.encounter as StaticEncounter).useStaticRewards:
			# if we have static rewards for this encounter:
			if playerWins:
				for reward in (PlayerResources.playerInfo.encounter as StaticEncounter).rewards:
					rewards.append(reward)
		else:
			# otherwise, we probably have random encounter rewards
			var randomEncounter: RandomEncounter = null
			if PlayerResources.playerInfo.encounter is RandomEncounter:
				randomEncounter = PlayerResources.playerInfo.encounter as RandomEncounter 
			# get enemy 1's rewards
			var reward: Reward = null
			# if enemy 1 was defeated:
			if battleController.enemyCombatant1.combatant != null and not battleController.enemyCombatant1.is_alive():
				# get its rewards: first, the random encounter's drop table if set for this combatant
				if randomEncounter != null and randomEncounter.combatant1Rewards != null and len(randomEncounter.combatant1Rewards.weightedRewards) > 0:
					var dropIdx = WeightedThing.pick_item(randomEncounter.combatant1Rewards.weightedRewards)
					if dropIdx > -1:
						reward = randomEncounter.combatant1Rewards.weightedRewards[dropIdx].reward
				elif battleController.enemyCombatant1.combatant.dropTable != null:
					# second, the combatant's own drop table:
					var dropIdx = WeightedThing.pick_item(battleController.enemyCombatant1.combatant.dropTable.weightedRewards)
					if dropIdx > -1:
						reward = battleController.enemyCombatant1.combatant.dropTable.weightedRewards[dropIdx].reward
				if reward != null:
					# if there was a reward, scale it up by the combatant's level
					reward = reward.scale_reward_by_level(battleController.enemyCombatant1.initialCombatantLv, battleController.enemyCombatant1.combatant.stats.level, Reward.CUSTOM_WIN_SCALE if playerWins else Reward.CUSTOM_LOSE_SCALE) \
						.scale_reward_by_modifiers(expModifier, goldModifier, itemsModifier)
					
			# no matter what, at least one reward should be returned here, even if null:
			rewards.append(reward)
			reward = null
			# if enemy 2 was present, get rewards (if defeated, otherwise null)
			if battleController.enemyCombatant2.combatant != null:
				if not battleController.enemyCombatant2.is_alive():
					# first, if the encounter had a drop table set for this combatant, use that:
					if randomEncounter != null and randomEncounter.combatant2Rewards != null and len(randomEncounter.combatant2Rewards.weightedRewards) > 0:
						var dropIdx = WeightedThing.pick_item(randomEncounter.combatant2Rewards.weightedRewards)
						if dropIdx > -1:
							reward = randomEncounter.combatant2Rewards.weightedRewards[dropIdx].reward
					elif battleController.enemyCombatant2.combatant.dropTable != null:
						# second, if the combatant has its own drop table, use that
						var dropIdx = WeightedThing.pick_item(battleController.enemyCombatant2.combatant.dropTable.weightedRewards)
						if dropIdx > -1:
							reward = battleController.enemyCombatant2.combatant.dropTable.weightedRewards[dropIdx].reward
					if reward != null:
						# if there was a reward, scale it up by the combatant's level
						reward = reward.scale_reward_by_level(battleController.enemyCombatant2.initialCombatantLv, battleController.enemyCombatant2.combatant.stats.level, Reward.CUSTOM_WIN_SCALE if playerWins else Reward.CUSTOM_LOSE_SCALE) \
							.scale_reward_by_modifiers(expModifier, goldModifier, itemsModifier)
				# if the enemy was present but not defeated, it explicitly gets null rewards. otherwise gets the found rewards
				rewards.append(reward)
			reward = null
			# if enemy 3 was present, get rewards (if defeated, otherwise null)
			if battleController.enemyCombatant3.combatant != null:
				if not battleController.enemyCombatant3.is_alive():
					# first, if the encounter had a drop table set for this combatant, use that:
					if randomEncounter != null and randomEncounter.combatant3Rewards != null and len(randomEncounter.combatant3Rewards.weightedRewards) > 0:
						var dropIdx = WeightedThing.pick_item(randomEncounter.combatant3Rewards.weightedRewards)
						if dropIdx > -1:
							reward = randomEncounter.combatant3Rewards.weightedRewards[dropIdx].reward
					elif battleController.enemyCombatant3.combatant.dropTable != null:
						# second, if the combatant has its own drop table, use that
						var dropIdx = WeightedThing.pick_item(battleController.enemyCombatant3.combatant.dropTable.weightedRewards)
						if dropIdx > -1:
							reward = battleController.enemyCombatant3.combatant.dropTable.weightedRewards[dropIdx].reward
					if reward != null:
						# if there was a reward, scale it up by the combatant's level
						reward = reward.scale_reward_by_level(battleController.enemyCombatant3.initialCombatantLv, battleController.enemyCombatant3.combatant.stats.level, Reward.CUSTOM_WIN_SCALE if playerWins else Reward.CUSTOM_LOSE_SCALE) \
						.scale_reward_by_modifiers(expModifier, goldModifier, itemsModifier)
				# if the enemy was present but not defeated, it explicitly gets null rewards. otherwise gets the found rewards
				rewards.append(reward)
		# if the win con is a Survive win con:
		if PlayerResources.playerInfo.encounter.winCon != null and PlayerResources.playerInfo.encounter.winCon is SurviveWinCon:
			var surviveWinCon: SurviveWinCon = PlayerResources.playerInfo.encounter.winCon as SurviveWinCon
			# if static rewards for achieving a Total Defeat victory are defined: check that WinCon's results
			if len(surviveWinCon.staticTotalDefeatRewards) > 0:
				var totalDefeatWinCon: TotalDefeatWinCon = TotalDefeatWinCon.new()
				var totalDefeatResult: WinCon.TurnResult = totalDefeatWinCon.get_result(battleController.get_all_combatant_nodes(), battleController.state)
				# if the player achieved Total Defeat victory: use those static rewards instead
				if totalDefeatResult == WinCon.TurnResult.PLAYER_WIN:
					rewards = []
					for reward: Reward in surviveWinCon.staticTotalDefeatRewards:
						rewards.append(reward.copy())
	return rewards

func _on_stats_panel_node_back_pressed():
	battlePanels.animatedBgPanel.visible = checkingSummonStats
	if menuState == BattleState.Menu.LEVEL_UP:
		end_battle()
	else:
		if checkingSummonStats:
			summonMinionPanel.visible = true
			summonMinionPanel.initial_focus()
		else:
			restore_focus()
	checkingSummonStats = false

func _on_combatant_details_clicked(combatantNode: CombatantNode):
	#open_stats(combatantNode.combatant) # disable for testing/designing
	pass

func _on_summon_minion_panel_back_pressed():
	battlePanels.animatedBgPanel.visible = false
	summonMenu.initial_focus()

func _on_inventory_panel_node_back_pressed():
	battlePanels.animatedBgPanel.visible = false
	if menuState == BattleState.Menu.SUMMON:
		summonMenu.initial_focus()
	if menuState == BattleState.Menu.ITEMS:
		allCommands.inventoryBtn.grab_focus()

func _on_quests_panel_node_back_pressed():
	battlePanels.animatedBgPanel.visible = false
	restore_focus()

func _on_focus_changed(control: Control):
	if control == battlePanels.flowOfBattle.fobButton and previousFocus != battlePanels.flowOfBattle.fobButton \
			and not battlePanels.flowOfBattle.fobButton.button_pressed and \
			not ('FlowOfBattle' in previousFocus.get_path().get_concatenated_names() or 'PanelsButtons' in previousFocus.get_path().get_concatenated_names()):
		battlePanels.flowOfBattle.fobButton.focus_neighbor_bottom = battlePanels.flowOfBattle.fobButton.get_path_to(previousFocus)
	if not statsPanel.visible and not inventoryPanel.visible and \
		not battlePanels.pauseMenu.visible and not battlePanels.questsMenu.visible and \
		not battlePanels.summonMinionPanel.visible:
		previousFocus = control

func _on_summon_minion_panel_show_stats_for_minion(minion: Combatant):
	checkingSummonStats = true
	summonMinionPanel.visible = false
	statsPanel.readOnly = true
	statsPanel.isMinionStats = true
	statsPanel.minion = minion
	statsPanel.stats = minion.stats
	statsPanel.savedStats = null
	statsPanel.toggle()
	battlePanels.animatedBgPanel.visible = true

func _on_summon_minion_panel_minion_summoned(minion: Combatant, shardSlot: InventorySlot):
	battlePanels.animatedBgPanel.visible = false
	var shard = null
	if shardSlot:
		PlayerResources.inventory.trash_item(shardSlot)
		shard = shardSlot.item as Shard
	battleController.summon_minion(minion.save_name(), shard)
	start_pre_battle()
