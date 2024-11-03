extends Resource
class_name CombatantAiLayer

## the amount of weight this layer has on the final decision of the AI
@export var weight: float = 1.0

func _init(
	i_weight: float = 1.0,
) -> void:
	weight = i_weight

# TODO: maybe it's ok to make `target` a type of combatant?
## get the weight for a combination of move effect and target
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, battleState: BattleState) -> float:
	if move == null or target == null:
		return -1
	var effect: MoveEffect = move.get_effect_of_type(effectType)
	if effect == null:
		return -1
	return 1

func set_move_used(move: Move, effectType: Move.MoveEffectType) -> void:
	pass # NOTE subclasses that care about what move was used should implement this method
