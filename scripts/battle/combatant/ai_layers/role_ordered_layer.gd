extends CombatantAiLayer
class_name RoleOrderedCombatantAiLayer

## the list of specific move roles to attempt to use in sequence
@export var roleList: Array[MoveEffect.Role] = []

## if true, continue to use moves with these roles forever, otherwise stop weighting these roles after the first iteration
@export var loop: bool = true

@export_storage var roleIdx: int = 0

## returns 1.5 if the move is the next move in the order, otherwise 0.5
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState)
	if baseWeight < 0:
		return -1
	
	if len(roleList) == 0 or roleIdx >= len(roleList):
		return 1
	
	var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
	if moveEffect.role == roleList[roleIdx]:
		return baseWeight * 1.5
	return baseWeight * 0.5

func set_move_used(move: Move, effectType: Move.MoveEffectType) -> void:
	var moveEffect: MoveEffect = move.get_effect_of_type(effectType)
	if moveEffect.role == roleList[roleIdx]:
		roleIdx += 1
		if loop:
			roleIdx = roleIdx % len(roleList)
