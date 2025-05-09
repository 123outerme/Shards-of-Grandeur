extends AbstractCombatantAiLayer
class_name SignatureCombatantAiLayer

## the multiplier for weighting to use when the move is a signature move
@export var signatureWeight: float = 1.25

func _init(
	i_weight: float = 1.0,
	i_subLayers: Array[AbstractCombatantAiLayer] = [],
	i_signatureWeight: float = 1.25,
) -> void:
	super(i_weight, i_subLayers)
	signatureWeight = i_signatureWeight

## if the move is a signature move, weight it higher
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState, allCombatantNodes: Array[CombatantNode]) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState, allCombatantNodes)
	if baseWeight < 0:
		return -1
	
	if user.combatant.stats.movepool.signatureMoves.has(move):
		return baseWeight * signatureWeight
	return baseWeight

func copy(copyStorage: bool = false)  -> SignatureCombatantAiLayer:
	return SignatureCombatantAiLayer.new(weight, copy_sublayers(copyStorage), signatureWeight)
