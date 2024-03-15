extends Resource
class_name SurgeChanges

@export var powerPerOrb: int = 0
@export var selfStatChangesPerOrb: StatChanges = StatChanges.new()
@export var targetStatChangesPerOrb: StatChanges = StatChanges.new()
@export var additionalStatusEffect: StatusEffect = null
@export var weakThresholdOrbs: int = 0
@export var strongThresholdOrbs: int = 0
@export var overwhelmingThresholdOrbs: int = 0
@export var additionalStatusTurnsPerOrb: float = 0
@export var additionalStatusChancePerOrb: float = 0

func _init(
	i_powerPerOrb = 0,
	i_selfStatChangesPerOrb = StatChanges.new(),
	i_targetStatChangesPerOrb = StatChanges.new(),
	i_additionalStatusEffect = null,
	i_weakThresholdOrbs = 0,
	i_strongThresholdOrbs = 0,
	i_overwhelmingThresholdOrbs = 0,
	i_additionalStatusTurnsPerOrb = 0,
	i_additionalStatusChancePerOrb = 0,
):
	powerPerOrb = i_powerPerOrb
	selfStatChangesPerOrb = i_selfStatChangesPerOrb
	targetStatChangesPerOrb = i_targetStatChangesPerOrb
	additionalStatusEffect = i_additionalStatusEffect
	weakThresholdOrbs = i_weakThresholdOrbs
	strongThresholdOrbs = i_strongThresholdOrbs
	overwhelmingThresholdOrbs = i_overwhelmingThresholdOrbs
	additionalStatusTurnsPerOrb = i_additionalStatusTurnsPerOrb
	additionalStatusChancePerOrb = i_additionalStatusChancePerOrb

func get_potency_for_additional_orbs_spent(additionalSpent: int) -> StatusEffect.Potency:
	if additionalSpent >= overwhelmingThresholdOrbs:
		return StatusEffect.Potency.OVERWHELMING
	if additionalSpent >= strongThresholdOrbs:
		return StatusEffect.Potency.STRONG
	if additionalSpent >= weakThresholdOrbs:
		return StatusEffect.Potency.WEAK
	return StatusEffect.Potency.NONE

func get_additional_status_turns(additionalSpent: int) -> int:
	return roundi(additionalSpent * additionalStatusTurnsPerOrb)

func get_additional_status_chance(additionalSpent: int) -> float:
	return roundi(additionalSpent * additionalStatusChancePerOrb)
