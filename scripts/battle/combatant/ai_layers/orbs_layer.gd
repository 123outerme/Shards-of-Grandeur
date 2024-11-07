extends CombatantAiLayer
class_name OrbsCombatantAiLayer

# the weight to apply when this move gives the most orbs
@export var mostOrbsWeight: float = 1.15

func _init(
	i_weight: float = 1.0,
	i_subLayers: Array[CombatantAiLayer] = [],
	i_mostOrbsWeight: float = 1.15,
) -> void:
	super(i_weight, i_subLayers)
	mostOrbsWeight = i_mostOrbsWeight

## the weight is based on whether this move (if Charge) gives the most orbs. If Surge, returns 1
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
	if baseWeight < 0:
		return -1
	
	if effectType == Move.MoveEffectType.SURGE:
		return baseWeight
	
	var orbsGained: int = move.chargeEffect.orbChange
	var highestOtherOrbsGained: int = 0
	
	for otherMove: Move in user.combatant.stats.moves:
		highestOtherOrbsGained = max(move.chargeEffect.orbChange, highestOtherOrbsGained)
	
	if orbsGained >= highestOtherOrbsGained:
		return baseWeight * mostOrbsWeight
	
	return baseWeight

func copy(copyStorage: bool = false) -> OrbsCombatantAiLayer:
	return OrbsCombatantAiLayer.new(weight, copy_sublayers(copyStorage), mostOrbsWeight)
