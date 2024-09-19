extends Node
class_name TurnExecutor

@export var battleController: BattleController
@export var battleUI: BattleUI

var allCombatants: Array[Combatant] = []

var turnQueue: TurnQueue = TurnQueue.new()
var escaping: bool = false
var result: WinCon.TurnResult = WinCon.TurnResult.NOTHING

func start_simulation():
	battleController.state.statusEffDamagedCombatants = []
	var combatants: Array[Combatant] = []
	var allCombatantNodes: Array[CombatantNode] = battleController.get_all_combatant_nodes()
	for combatantNode in allCombatantNodes:
		if combatantNode.is_alive():
			allCombatants.append(combatantNode.combatant)
	
	for combatantNode in allCombatantNodes:
		if combatantNode.is_alive():
			if combatantNode.role == CombatantNode.Role.ENEMY:
				combatantNode.get_command(allCombatantNodes)
			combatants.append(combatantNode.combatant)
			combatantNode.combatant.command.get_targets_from_combatant_nodes(allCombatantNodes)
			# apply before-round effects
			if combatantNode.combatant.statusEffect != null:
				battleController.state.statusEffDamagedCombatants.append_array(
					combatantNode.combatant.statusEffect.apply_status(combatantNode.combatant, allCombatants, BattleCommand.ApplyTiming.BEFORE_ROUND)
				)
			if combatantNode.combatant.stats.equippedWeapon != null:
				combatantNode.combatant.stats.equippedWeapon.apply_effects(combatantNode.combatant, BattleCommand.ApplyTiming.BEFORE_ROUND)
			if combatantNode.combatant.stats.equippedArmor != null:
				combatantNode.combatant.stats.equippedArmor.apply_effects(combatantNode.combatant, BattleCommand.ApplyTiming.BEFORE_ROUND)
	turnQueue = TurnQueue.new(combatants)

func play_turn():
	var allCombatantNodes: Array[CombatantNode] = battleController.get_all_combatant_nodes()
	var combatant: Combatant = turnQueue.peek_next()
	if combatant != null: # apply before-damage-calc status
		battleController.state.statusEffDamagedCombatants = []
		combatant.command.get_targets_from_combatant_nodes(allCombatantNodes) # make sure to get all commands before applying statuses
		# apply status effect effects Before Dmg Calc
		if combatant.statusEffect != null:
			battleController.state.statusEffDamagedCombatants.append_array(
				combatant.statusEffect.apply_status(combatant, allCombatants, BattleCommand.ApplyTiming.BEFORE_DMG_CALC)
			)
		# apply equipment boosts Before Dmg Calc
		#if combatant.stats.equippedArmor != null:
		#	combatant.stats.equippedArmor.apply_effects(combatant, BattleCommand.ApplyTiming.BEFORE_DMG_CALC)
		#if combatant.stats.equippedWeapon != null:
		#	combatant.stats.equippedWeapon.apply_effects(combatant, BattleCommand.ApplyTiming.BEFORE_DMG_CALC)
		# Execute the command: attack, use item, attempt to flee, etc.
		escaping = combatant.command.execute_command(combatant, allCombatantNodes) # perform all necessary calculations
		# apply after-damage-calc status
		if combatant.statusEffect != null:
			battleController.state.statusEffDamagedCombatants.append_array(
				combatant.statusEffect.apply_status(combatant, allCombatants, BattleCommand.ApplyTiming.AFTER_DMG_CALC)
			)
		# apply equipment boosts After Dmg Calc
		#if combatant.stats.equippedArmor != null:
		#	combatant.stats.equippedArmor.apply_effects(combatant, BattleCommand.ApplyTiming.AFTER_DMG_CALC)
		#if combatant.stats.equippedWeapon != null:
		#	combatant.stats.equippedWeapon.apply_effects(combatant, BattleCommand.ApplyTiming.AFTER_DMG_CALC)
		for targetIdx: int in range(len(combatant.command.targets)):
			var defender: Combatant = combatant.command.targets[targetIdx]
			if defender.statusEffect != null: # apply "specifically afer taking damage" statuses
				battleController.state.statusEffDamagedCombatants.append_array(
					defender.statusEffect.apply_status(defender, allCombatants, BattleCommand.ApplyTiming.AFTER_RECIEVING_DMG)
				)
			# if a move was used: get the move effect
			if combatant.command.type == BattleCommand.Type.MOVE and combatant.command.move != null:
				var moveEffect: MoveEffect = combatant.command.move.get_effect_of_type(combatant.command.moveEffectType)
				if combatant.command.moveEffectType == Move.MoveEffectType.SURGE: # apply surge effects
					moveEffect = moveEffect.apply_surge_changes(combatant.command.orbChange * -1)
				# if the move dealt direct (non-redirected) damage to the defender, then apply After Recieving Damage timing equipment effects
				if moveEffect.power > 0:
					var equipmentProcd: Array[Item] = []
					if defender.stats.equippedArmor != null:
						var applied: bool = defender.stats.equippedArmor.apply_effects(defender, BattleCommand.ApplyTiming.AFTER_RECIEVING_DMG)
						if applied:
							equipmentProcd.append(defender.stats.equippedArmor)
					if defender.stats.equippedWeapon != null:
						var applied: bool = defender.stats.equippedWeapon.apply_effects(defender, BattleCommand.ApplyTiming.AFTER_RECIEVING_DMG)
						if applied:
							equipmentProcd.append(defender.stats.equippedArmor)
					combatant.command.commandResult.equipmentProcd[targetIdx] = equipmentProcd
		
		update_turn_text()
	else:
		battleController.state.statusEffDamagedCombatants = []
		for combatantNode in battleController.get_all_combatant_nodes(): # apply after-round effects
			if combatantNode.is_alive():
				if combatantNode.combatant.statusEffect != null:
					battleController.state.statusEffDamagedCombatants.append_array(
						combatantNode.combatant.statusEffect.apply_status(combatantNode.combatant, allCombatants, BattleCommand.ApplyTiming.AFTER_ROUND)
					)
				if combatantNode.combatant.stats.equippedWeapon != null:
					combatantNode.combatant.stats.equippedWeapon.apply_effects(combatantNode.combatant, BattleCommand.ApplyTiming.AFTER_ROUND)
				if combatantNode.combatant.stats.equippedArmor != null:
					combatantNode.combatant.stats.equippedArmor.apply_effects(combatantNode.combatant, BattleCommand.ApplyTiming.AFTER_ROUND)
		battleUI.set_menu_state(BattleState.Menu.POST_ROUND)
	
func update_turn_text() -> bool:
	var allCombatantNodes: Array[CombatantNode] = battleController.get_all_combatant_nodes()
	var text: String = ''
	
	''' enabling ability to set breakpoint for debugging status dmg particles
	if len(battleController.state.statusEffDamagedCombatants) > 0:
		print('status dmgd combatants')
	#'''
	
	if battleUI.menuState == BattleState.Menu.PRE_BATTLE or battleUI.menuState == BattleState.Menu.PRE_ROUND or battleUI.menuState == BattleState.Menu.POST_ROUND:
		if len(battleController.state.calcdStateStrings) == 0:
			calculate_intermediate_state_strings(allCombatantNodes)
			if len(battleController.state.calcdStateStrings) == 0:
				battleUI.advance_intermediate_state(result)
				return false
			else:
				text = battleController.state.calcdStateStrings[0]
		elif battleController.state.calcdStateIndex < len(battleController.state.calcdStateStrings):
			text = battleController.state.calcdStateStrings[battleController.state.calcdStateIndex]
		
		battleController.battleAnimationManager.play_intermediate_round_animations(battleController.state)
	if battleUI.menuState == BattleState.Menu.RESULTS:
		var combatant: Combatant = turnQueue.peek_next()
		var defenders: Array[Combatant] = []
		if combatant != null:
			combatant.command.get_targets_from_combatant_nodes(allCombatantNodes)
			text = combatant.command.get_command_results(combatant)
			defenders.append_array(combatant.command.targets)
			for interceptor in combatant.command.interceptingTargets:
				if not interceptor in defenders:
					defenders.append(interceptor)
			if combatant.statusEffect != null:
				text += ' ' + combatant.statusEffect.get_status_effect_str(combatant, allCombatants, BattleCommand.ApplyTiming.AFTER_DMG_CALC)
			for defender in defenders:
				if not defender == combatant and defender.statusEffect != null:
					text += ' ' + defender.statusEffect.get_status_effect_str(defender, allCombatants, BattleCommand.ApplyTiming.AFTER_DMG_CALC)
				# if the defender did not intercept the attack (was directed at this defender):
				if defender in combatant.command.targets:
					# if a move was used: get the move effect
					if combatant.command.type == BattleCommand.Type.MOVE and combatant.command.move != null:
						var moveEffect: MoveEffect = combatant.command.move.get_effect_of_type(combatant.command.moveEffectType)
						if combatant.command.moveEffectType == Move.MoveEffectType.SURGE: # apply surge effects
							moveEffect = moveEffect.apply_surge_changes(combatant.command.orbChange * -1)
						# if the move dealt damage to the defender, then show the After Recieving Dmg equipment effects
						if moveEffect.power > 0:
							if defender.stats.equippedWeapon != null:
								var afterDmgText: String = defender.stats.equippedWeapon.get_apply_text(defender, BattleCommand.ApplyTiming.AFTER_RECIEVING_DMG)
								if afterDmgText != '':
									text += ' ' + afterDmgText
							if defender.stats.equippedArmor != null:
								var afterDmgText: String = defender.stats.equippedArmor.get_apply_text(defender, BattleCommand.ApplyTiming.AFTER_RECIEVING_DMG)
								if afterDmgText != '':
									text += ' ' + afterDmgText

		var userNode: CombatantNode = null
		for combatantNode: CombatantNode in allCombatantNodes:
			if combatantNode.combatant == combatant:
				userNode = combatantNode
			
		if userNode != null and combatant.command.commandResult != null:
			battleController.battleAnimationManager.play_turn_animation(userNode, combatant.command, battleController.state.statusEffDamagedCombatants)
	
	battleUI.results.show_text(text)
	return text != ''

func finish_turn() -> WinCon.TurnResult:
	var lastCombatant: Combatant = turnQueue.pop() # remove the turn from the queue
	if lastCombatant != null:
		lastCombatant.command = null # remove the command from the previous turn's combatant
	result = check_battle_end_conditions()
	if result == WinCon.TurnResult.NOTHING:
		play_turn() # go to the next turn
	return result

func is_on_last_turn() -> bool:
	# if length of the queue is 1, this is the last turn. If it's 0, the round is over, but this should still return true technically
	return len(turnQueue.combatants) <= 1

func get_current_turn_combatant() -> Combatant:
	return turnQueue.peek_next()

func check_battle_end_conditions() -> WinCon.TurnResult:
	for combatantNode in battleController.get_all_combatant_nodes():
		if combatantNode.combatant != null:
			combatantNode.combatant.update_downed()
		if not combatantNode.is_alive(): # if combatant is not alive (after being updated)
			combatantNode.update_hp_tag() # then the combatant should be shown as defeated
	var turnResult: WinCon.TurnResult = PlayerResources.playerInfo.encounter.get_win_con_result(battleController.get_all_combatant_nodes(), battleController.state)
	if turnResult != WinCon.TurnResult.NOTHING:
		return turnResult
	if escaping: # if escaping
		turnQueue.empty() # end the round immediately
		return WinCon.TurnResult.ESCAPE
	return WinCon.TurnResult.NOTHING

func calculate_intermediate_state_strings(allCombatantNodes: Array[CombatantNode]):
	battleController.state.calcdStateStrings = []
	battleController.state.calcdStateCombatants = []
	battleController.state.calcdStateDamage = []
	battleController.state.calcdStateEquipmentProcd = []
	battleController.state.calcdStateStatBoosts = []
	for combatantNode in allCombatantNodes:
		# instead of combatantNode.is_alive(), check if visible and combatant is not null
		if combatantNode.combatant != null and combatantNode.visible:
			if battleUI.menuState == BattleState.Menu.PRE_BATTLE:
				var procdEquipment: Array[Item] = []
				var equippedWeaponText: String = ''
				var equippedArmorText: String = ''
				if combatantNode.combatant.stats.equippedWeapon != null:
					equippedWeaponText = combatantNode.combatant.stats.equippedWeapon.get_apply_text(combatantNode.combatant, BattleCommand.ApplyTiming.BEFORE_BATTLE)
					if equippedWeaponText != '':
						procdEquipment.append(combatantNode.combatant.stats.equippedWeapon)
				if combatantNode.combatant.stats.equippedArmor != null:
					equippedArmorText = combatantNode.combatant.stats.equippedArmor.get_apply_text(combatantNode.combatant, BattleCommand.ApplyTiming.BEFORE_BATTLE)
					if equippedArmorText != '':
						procdEquipment.append(combatantNode.combatant.stats.equippedArmor)
				if equippedWeaponText != '' or equippedArmorText != '':
					if equippedWeaponText != '' and equippedArmorText != '':
						equippedWeaponText += ' '
					battleController.state.calcdStateStrings.append(equippedWeaponText + equippedArmorText)
					battleController.state.calcdStateCombatants.append(combatantNode.combatant)
					battleController.state.calcdStateEquipmentProcd.append(procdEquipment)
			
			if battleUI.menuState == BattleState.Menu.PRE_ROUND or battleUI.menuState == BattleState.Menu.POST_ROUND:
				if battleUI.menuState == BattleState.Menu.POST_ROUND and not (combatantNode.is_alive() and result == WinCon.TurnResult.NOTHING):
					continue
				
				var timing: BattleCommand.ApplyTiming = BattleCommand.ApplyTiming.BEFORE_ROUND if battleUI.menuState == BattleState.Menu.PRE_ROUND else BattleCommand.ApplyTiming.AFTER_ROUND
				var statusEffectString: String = ''
				var dmg: int = 0
				if combatantNode.combatant.statusEffect != null:
					dmg = combatantNode.combatant.statusEffect.get_status_effect_damage(combatantNode.combatant, allCombatants, timing)
					statusEffectString = combatantNode.combatant.statusEffect.get_status_effect_str(combatantNode.combatant, allCombatants, timing)
				
				var equippedWeaponText: String = ''
				var equippedArmorText: String = ''
				var procdEquipment: Array[Item] = []
				
				if combatantNode.combatant.stats.equippedWeapon != null:
					equippedWeaponText = combatantNode.combatant.stats.equippedWeapon.get_apply_text(combatantNode.combatant, timing)
					if equippedWeaponText != '':
						procdEquipment.append(combatantNode.combatant.stats.equippedWeapon)
				if combatantNode.combatant.stats.equippedArmor != null:
					equippedArmorText = combatantNode.combatant.stats.equippedArmor.get_apply_text(combatantNode.combatant, timing)
					if equippedArmorText != '':
						procdEquipment.append(combatantNode.combatant.stats.equippedArmor)
				if equippedWeaponText != '' or equippedArmorText != '':
					if equippedWeaponText != '' and equippedArmorText != '':
						equippedWeaponText += ' '
					if statusEffectString != '':
						statusEffectString += ' '
					statusEffectString += equippedWeaponText + equippedArmorText
				if statusEffectString != '':
					battleController.state.calcdStateStrings.append(statusEffectString)
					battleController.state.calcdStateCombatants.append(combatantNode.combatant)
					battleController.state.calcdStateEquipmentProcd.append(procdEquipment)
					battleController.state.calcdStateDamage.append(dmg)

func advance_precalcd_text() -> bool:
	battleController.state.calcdStateIndex += 1
	update_turn_text()
	return battleController.state.calcdStateIndex >= len(battleController.state.calcdStateStrings)

func find_combatant_node_by_combatant(cNodes: Array[CombatantNode], c: Combatant) -> CombatantNode:
	for node in cNodes:
		if node.combatant == c:
			return node
	return null
