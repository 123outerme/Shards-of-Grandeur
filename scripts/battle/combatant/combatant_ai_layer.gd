extends Resource
class_name CombatantAiLayer

## the amount of weight this layer has on the final decision of the AI
@export var weight: float = 1.0

## sub-layers that act as additional weighting on this layer
@export var subLayers: Array[CombatantAiLayer] = []

func _init(
	i_weight: float = 1.0,
	i_subLayers: Array[CombatantAiLayer] = [],
) -> void:
	weight = i_weight
	subLayers = i_subLayers

## get the weight for a combination of move effect and target
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	if move == null or target == null:
		return -1
	var effect: MoveEffect = move.get_effect_of_type(effectType)
	if effect == null:
		return -1
	
	var subLayersWeight: float = 1
	for layer: CombatantAiLayer in subLayers:
		if layer == null:
			continue
		
		var subLayerWeight: float = layer.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
		if subLayerWeight < 0:
			subLayersWeight = -1
		else:
			subLayerWeight = lerpf(1, subLayerWeight, weight)
			subLayersWeight *= subLayerWeight
	return subLayersWeight

func set_move_used(move: Move, effectType: Move.MoveEffectType) -> void:
	pass # NOTE subclasses that care about what move was used should implement this method
