extends Resource
class_name MoveEffect

enum Role {
	OTHER = 0,
	SINGLE_TARGET_DAMAGE = 1,
	AOE_DAMAGE = 2,
	BUFF = 3,
	DEBUFF = 4,
	HEAL = 5
}

@export var role: Role = Role.OTHER
@export_range(-100, 100) var power: int = 0 # negative power is healing, positive power is damage
@export_range(-10, 10) var orbChange: int = 0 # negative is orb surge, positive is orb charge
@export var targets: BattleCommand.Targets = BattleCommand.Targets.SELF
@export var selfStatChanges: StatChanges = StatChanges.new()
@export var targetStatChanges: StatChanges = StatChanges.new()
@export var statusEffect: StatusEffect = null
@export var selfGetsStatus: bool = false # if false, target gets status. If true, give it self
@export var statusChance: float = 0.0
@export var surgeChanges: SurgeChanges = null
@export_multiline var effectDescription: String = ''

static func role_to_string(r: Role) -> String:
	match r:
		Role.OTHER:
			return 'Other'
		Role.SINGLE_TARGET_DAMAGE:
			return 'Single Target'
		Role.AOE_DAMAGE:
			return 'AOE'
		Role.BUFF:
			return 'Buff'
		Role.DEBUFF:
			return 'Debuff'
		Role.HEAL:
			return 'Heal'
	return 'UNKOWN'

func _init(
	i_role = Role.OTHER,
	i_power = 0,
	i_orbChange = 0,
	i_targets = BattleCommand.Targets.SELF,
	i_selfStatChanges = StatChanges.new(),
	i_targetStatChanges = StatChanges.new(),
	i_statusEffect = null,
	i_selfGetsStatus = false,
	i_statusChance = 0.0,
	i_surgeChanges = null,
	i_effectDesc = '',
):
	role = i_role
	power = i_power
	orbChange = i_orbChange
	targets = i_targets
	selfStatChanges = i_selfStatChanges
	targetStatChanges = i_targetStatChanges
	statusEffect = i_statusEffect
	selfGetsStatus = i_selfGetsStatus
	statusChance = i_statusChance
	surgeChanges = i_surgeChanges
	effectDescription = i_effectDesc

func apply_surge_changes(orbsSpent: int) -> MoveEffect:
	if surgeChanges == null:
		return self
	
	var additionalOrbs: int = (orbChange * -1) - orbsSpent
	var newEffect = copy()
	
	newEffect.power += surgeChanges.powerPerOrb * additionalOrbs
	
	var finalSelfStatChanges: StatChanges = surgeChanges.selfStatChangesPerOrb.duplicate()
	finalSelfStatChanges.times(additionalOrbs)
	newEffect.selfStatChanges.stack(finalSelfStatChanges)
	
	var finalTargetStatChanges: StatChanges = surgeChanges.targetStatChangesPerOrb.duplicate()
	finalTargetStatChanges.times(additionalOrbs)
	newEffect.targetStatChanges.stack(finalTargetStatChanges)
	
	newEffect.statusChance = min(1, newEffect.statusChance + surgeChanges.get_additional_status_chance(additionalOrbs))
	
	if surgeChanges.additionalStatusEffect != null:
		newEffect.statusEffect = surgeChanges.additionalStatusEffect.copy()
		newEffect.statusEffect.potency = surgeChanges.get_potency_for_additional_orbs_spent(additionalOrbs)
		newEffect.statusEffect.turnsLeft += surgeChanges.get_additional_turns(additionalOrbs)
	
	return newEffect
	
func copy() -> MoveEffect:
	var newEffect: MoveEffect = MoveEffect.new(
		role,
		power,
		orbChange,
		targets,
		selfStatChanges.duplicate(),
		targetStatChanges.duplicate(),
		statusEffect,
		selfGetsStatus,
		statusChance,
		surgeChanges,
		effectDescription
	)
	return newEffect
