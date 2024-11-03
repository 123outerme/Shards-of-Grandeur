extends Resource
class_name CombatantAi

enum OrbSpendStrategy {
	GREEDY = 0, ## spends orbs as soon as possible
	BIG_SPENDER = 1, ## saves up a lot of orbs and dumps them all
	BIG_SAVER = 2, ## saves up orbs, spends a few, keeps saving, spends a few, etc.
}

## the AI Layers that make up the combatant's battle logic
@export var layers: Array[CombatantAiLayer] = []

## the strategy to use when weighing a Surge move, to account for how many orbs should be spent
@export var orbSpendStrategy: OrbSpendStrategy = OrbSpendStrategy.GREEDY

## Parameter in range [0, 1.5] used to increase/decrease staleness falloff: 1.5 = no initial falloff for the second move in a row, and 1 = heavy initial falloff. Use 0 for no staleness penalty
@export_range(0, 1.5) var stalenessTolerance: float = 1.3

@export_storage var lastMove: Move = null
@export_storage var lastMovesEffect: Move.MoveEffectType = Move.MoveEffectType.NONE
@export_storage var timesUsedLastMove: int = 0

func _init(
	i_layers: Array[CombatantAiLayer] = [],
	i_lastMove: Move = null,
	i_lastMovesEffect: Move.MoveEffectType = Move.MoveEffectType.NONE,
	i_timesUsedLastMove: int = 0,
) -> void:
	layers = i_layers
	lastMove = i_lastMove
	lastMovesEffect = i_lastMovesEffect
	timesUsedLastMove = i_timesUsedLastMove

func get_command_for_turn(user: CombatantNode, allCombatantNodes: Array[CombatantNode], battleState: BattleState) -> BattleCommand:
	var battleCommand: BattleCommand = null
	var highestWeight: float = -1
	
	var highestOrbCharge: int = 0
	for move: Move in user.combatant.stats.moves:
		if move.chargeEffect.orbChange > highestOrbCharge:
			highestOrbCharge = move.chargeEffect.orbChange
	
	for move: Move in user.combatant.stats.moves:
		for effectType: Move.MoveEffectType in [Move.MoveEffectType.CHARGE, Move.MoveEffectType.SURGE]:
			var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
			var targets: Array[CombatantNode] = user.get_targetable_combatant_nodes(allCombatantNodes, moveEffect.targets)
			if len(targets) == 0:
				continue
			var orbs: int = moveEffect.orbChange
			if effectType == Move.MoveEffectType.SURGE and could_combatant_surge(user.combatant, moveEffect):
				orbs = get_orbs_amount(user.combatant, moveEffect)
			var moveWeight: float = 1 if len(targets) > 0 else -1
			var highestWeightedTarget: CombatantNode = null
			for target: CombatantNode in targets:
				var targetWeight: float = get_move_effect_on_target_weight(user, move, effectType, orbs, target, targets, battleState)
				if BattleCommand.is_command_multi_target(moveEffect.targets):
					moveWeight *= targetWeight
				else:
					if highestWeightedTarget == null or moveWeight < targetWeight:
						moveWeight = targetWeight
						highestWeightedTarget = target
				print('> DEBUG: ', move.moveName, ' / ', Move.move_effect_type_to_string(effectType), ' weight against ', target.battlePosition, ' == ', targetWeight)
			if effectType == Move.MoveEffectType.CHARGE and moveEffect.orbChange == highestOrbCharge:
				moveWeight *= 1.05 # 5% bonus to charge moves that charge the most orbs
			print('>> DEBUG: ', move.moveName, ' / ', Move.move_effect_type_to_string(effectType), ' overall weight == ', moveWeight)
			if moveWeight >= 0 and moveWeight > highestWeight:
				highestWeight = moveWeight
				var targetStrings: Array[String] = []
				if BattleCommand.is_command_multi_target(moveEffect.targets):
					for target: CombatantNode in targets:
						targetStrings.append(target.battlePosition)
				elif highestWeightedTarget != null:
					targetStrings.append(highestWeightedTarget.battlePosition)
				battleCommand = BattleCommand.new(
					BattleCommand.Type.MOVE,
					move,
					effectType,
					orbs,
					null,
					targetStrings,
				)
	
	if battleCommand == null:
		battleCommand = BattleCommand.new()
	
	return battleCommand

# TODO can I replace Variant with Combatant/CombatantNode?
func get_move_effect_on_target_weight(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	var weight: float = get_move_effect_staleness_weight(move, effectType)
	for layer: CombatantAiLayer in layers:
		var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
		var layerWeight: float = 1
		if could_combatant_surge(user.combatant, moveEffect):
			layerWeight = layer.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
			if layerWeight >= 0:
				layerWeight = lerpf(1, layerWeight, layer.weight) # if the decision by that layer isn't weighted highly, it approaches a x1 multiplier
		else:
			layerWeight = 0
		if layerWeight < 0:
			weight = -1
		else:
			weight *= layerWeight
	return weight

## get the weighting for the move effect based on its staleness amount
func get_move_effect_staleness_weight(move: Move, effectType: Move.MoveEffectType) -> float:
	if move == null:
		return -1
	if move != lastMove or effectType != lastMovesEffect or stalenessTolerance <= 0:
		return 1
	return stalenessTolerance / (0.5 * timesUsedLastMove + 1)

func set_move_used(move: Move, effectType: Move.MoveEffectType) -> void:
	if lastMove == move and effectType == lastMovesEffect:
		timesUsedLastMove += 1
	else:
		lastMove = move
		effectType = lastMovesEffect
		timesUsedLastMove = 1
	
	for layer: CombatantAiLayer in layers:
		layer.set_move_used(move, effectType)

func could_combatant_surge(combatant: Combatant, effect: MoveEffect) -> bool:
	if effect.orbChange >= 0:
		return true # no cost required to charge orbs
	
	if Combatant.useSurgeReqs != null and not Combatant.useSurgeReqs.is_valid():
		return false # AI can't use surge moves yet
	
	return effect.orbChange * -1 <= combatant.orbs

func get_spend_orbs_likelihood(combatant: Combatant, effect: MoveEffect) -> float:
	if not could_combatant_surge(combatant, effect):
		return 0
	
	var spendingOrbs: int = effect.orbChange * -1
	
	var spendChance: float = 0 # default: never spend orbs
	
	match orbSpendStrategy:
		OrbSpendStrategy.GREEDY:
			spendChance = 1 if combatant.orbs >= spendingOrbs else 0 # if we have the orbs, do it
		OrbSpendStrategy.BIG_SPENDER:
			var orbsRatio: float = combatant.orbs / 6.0 # once combatant has 6+ orbs, they are GUARANTEED to start spending
			spendChance = (pow(orbsRatio, 2) + orbsRatio) / 2.0
		OrbSpendStrategy.BIG_SAVER:
			var orbsRatio: float = (combatant.orbs - spendingOrbs) / 2.0 # once combatant has 2+ more orbs than is required to surge, they are GUARANTEED to start spending
			spendChance = (pow(orbsRatio, 2) + orbsRatio) / 2.0
			#return combatant.orbs >= spendingOrbs + 2 or orbs == 10 # if we have 2 more orbs than required, or we have 10 orbs, then do it
	if (combatant.currentHp as float) / combatant.stats.maxHp <= 0.33:
		spendChance += 0.5 # 50% more likely to spend orbs when below 33% health
	
	return min(1, max(0, spendChance))

func get_orbs_amount(combatant: Combatant, effect: MoveEffect) -> int:
	if effect.orbChange >= 0:
		return effect.orbChange
	# surge moves only, here
	match orbSpendStrategy:
		OrbSpendStrategy.GREEDY, OrbSpendStrategy.BIG_SPENDER:
			return combatant.orbs * -1
		OrbSpendStrategy.BIG_SAVER:
			var spendRatio: float = 0.75
			if (combatant.currentHp as float) / combatant.stats.maxHp <= 0.33:
				spendRatio = 1.0
			return min(Combatant.MAX_ORBS, max(effect.orbChange, floori(combatant.orbs * spendRatio)))
	return effect.orbChange

func copy() -> CombatantAi:
	var newAi: CombatantAi = CombatantAi.new(
		layers.duplicate(false),
	)
	return newAi
