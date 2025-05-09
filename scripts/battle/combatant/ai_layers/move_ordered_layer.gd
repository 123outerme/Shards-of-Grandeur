extends AbstractCombatantAiLayer
class_name MoveOrderedCombatantAiLayer

## the list of specific moves to attempt to use in sequence
@export var moveList: Array[Move] = []

@export var moveListAttemptSurge: Array[bool] = []

## if true, continue to use these moves forever, otherwise stop weighting these moves after the first iteration
@export var loop: bool = true

@export_storage var moveIdx: int = 0

func _init(
	i_weight: float = 1.0,
	i_subLayers: Array[AbstractCombatantAiLayer] = [],
	i_moveList: Array[Move] = [],
	i_moveListAttemptSurge: Array[bool] = [],
	i_moveIdx: int = 0,
) -> void:
	super(weight, subLayers)
	moveList = i_moveList.duplicate(false)
	moveListAttemptSurge = i_moveListAttemptSurge.duplicate(false)
	moveIdx = i_moveIdx

## returns 1.5 if the move is the next move in the order, otherwise 0.5
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState, allCombatantNodes: Array[CombatantNode]) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState, allCombatantNodes)
	if baseWeight < 0:
		return -1
	
	var weight: float = 1
	
	if len(moveList) == 0 or moveIdx >= len(moveList):
		return baseWeight
	
	if move == moveList[moveIdx]:
		weight = 1.4
	else:
		weight = 0.6
	
	if moveIdx < len(moveListAttemptSurge):
		if moveListAttemptSurge[moveIdx] and effectType == Move.MoveEffectType.SURGE:
			weight *= 1.5
	
	return baseWeight * weight

func set_move_used(move: Move, effectType: Move.MoveEffectType) -> void:
	if move == moveList[moveIdx]:
		moveIdx += 1
		if loop:
			moveIdx = moveIdx % len(moveList)

func copy(copyStorage: bool = false) -> MoveOrderedCombatantAiLayer:
	var layer: MoveOrderedCombatantAiLayer = MoveOrderedCombatantAiLayer.new(weight, copy_sublayers(copyStorage), moveList, moveListAttemptSurge)
	
	if copyStorage:
		layer.moveIdx = moveIdx
	
	return layer
