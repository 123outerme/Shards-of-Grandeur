extends AbstractCombatantAiLayer
class_name ConditionalCombatantAiLayer

enum ConditionalType {
	NONE = 0, ## no conditional check; will always be NOT met
	SELF_HP_IN_RANGE = 1, ## condition is met when self HP is within a range of max HP percentage `conditionalNum1` <= x <= `conditionalNum2`
	TARGET_HP_IN_RANGE = 2, ## condition is met when target HP drops to or below below a percentage of max HP `conditionalNum1` <= x <= `conditionalNum2`
	SELF_IS_STATUSED = 3, ## condition is met if self is statused
	TARGET_IS_STATUSED = 4, ## condition is met when target is statused
	SELF_ORBS_IN_RANGE = 5, ## condition is met when self has orbs within a range `conditionalNum1` <= x <= `conditionalNum2`
	TARGET_ORBS_IN_RANGE = 6, ## condition is met when target has orbs within a range `conditionalNum1` <= x <= `conditionalNum2`
	TURN_COUNT_IN_RANGE = 7, ## condition is met when the turn count is within a range `conditionalNum1` <= x <= `conditionalNum2` (`conditionalNum2` = -1 for no bound)
}

## the returned weight if the condition is not met
@export var notMetWeight: float = 0

## the returnd weight if the condition is met
@export var metWeight: float = 1

## the condition to be tested for
@export var condition: ConditionalType = ConditionalType.NONE

## if true, use `metWeight` when the condition is NOT met, and vice versa.
@export var inverse: bool = false
# for neatness of layer display, since metWeight doesn't have to be greater than notMetWeight, but it would be more confusing to try to decipher

## if true, once the condition is met, the `metWeight` will always be used until the end of battle
@export var sticky: bool = false

## float value to set the parameters of the conditional check. Meaning and units dependent on the selected condition
@export var conditionalNum1: float = 0

##  float value to set the parameters of the conditional check. Meaning and units dependent on the selected condition
@export var conditionalNum2: float = 0

@export_storage var conditionMetOnce: bool = false

func _init(
	i_weight: float = 1.0,
	i_subLayers: Array[CombatantAiLayerBase] = [],
	i_notMetWeight: float = 0,
	i_metWeight: float = 1,
	i_condition: ConditionalType = ConditionalType.NONE,
	i_inverse: bool = false,
	i_sticky: bool = false,
	i_conditionalNum1: float = 0,
	i_conditionalNum2: float = 0,
	i_conditionMetOnce: bool = false,
) -> void:
	super(i_weight, i_subLayers)
	notMetWeight = i_notMetWeight
	metWeight = i_metWeight
	condition = i_condition
	inverse = i_inverse
	sticky = i_sticky
	conditionalNum1 = i_conditionalNum1
	conditionalNum2 = i_conditionalNum2
	conditionMetOnce = i_conditionMetOnce
	

## the final weight is modified based on if a preset condition is currently met (or met at least once before, if "sticky")
func weight_move_effect_on_target(user: CombatantNode, move: Move, effectType: Move.MoveEffectType, orbs: int, target: CombatantNode, targets: Array[CombatantNode], battleState: BattleState, allCombatantNodes: Array[CombatantNode]) -> float:
	var baseWeight: float = super.weight_move_effect_on_target(user, move, effectType, orbs, target, targets, battleState, allCombatantNodes)
	if baseWeight < 0:
		return -1
	
	var conditionMet: bool = false
	
	match condition:
		ConditionalType.SELF_HP_IN_RANGE:
			var hpPercent: float = (user.combatant.currentHp as float) / user.combatant.stats.maxHp
			conditionMet = conditionalNum1 <= hpPercent and hpPercent <= conditionalNum2
		ConditionalType.TARGET_HP_IN_RANGE:
			var hpPercent: float = (target.combatant.currentHp as float) / target.combatant.stats.maxHp
			conditionMet = conditionalNum1 <= hpPercent and hpPercent <= conditionalNum2
		ConditionalType.SELF_IS_STATUSED:
			conditionMet = user.combatant.statusEffect != null
		ConditionalType.TARGET_IS_STATUSED:
			conditionMet = target.combatant.statusEffect != null
		ConditionalType.SELF_ORBS_IN_RANGE:
			conditionMet = conditionalNum1 <= user.combatant.orbs and user.combatant.orbs <= conditionalNum2
		ConditionalType.TARGET_ORBS_IN_RANGE:
			conditionMet = conditionalNum1 <= target.combatant.orbs and target.combatant.orbs <= conditionalNum2
		ConditionalType.TURN_COUNT_IN_RANGE:
			conditionMet = conditionalNum1 <= battleState.turnNumber
			if conditionalNum2 >= 0:
				conditionMet = conditionMet and battleState.turnNumber <= conditionalNum2
	
	if inverse:
		conditionMet = not conditionMet
	
	if conditionMet:
		conditionMetOnce = true
	if conditionMetOnce and sticky:
		conditionMet = true
	
	return baseWeight * (metWeight if conditionMet else notMetWeight)

func copy(copyStorage: bool = false) -> ConditionalCombatantAiLayer:
	var layer: ConditionalCombatantAiLayer = ConditionalCombatantAiLayer.new(
		weight,
		copy_sublayers(copyStorage),
		notMetWeight,
		metWeight,
		condition,
		inverse,
		sticky,
		conditionalNum1,
		conditionalNum2,
	)
	
	if copyStorage:
		layer.conditionMetOnce = conditionMetOnce
	
	return layer
