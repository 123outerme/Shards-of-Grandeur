extends Resource
class_name Move

enum DmgCategory {
	PHYSICAL = 0,
	MAGIC = 1,
	AFFINITY = 2,
}

enum Role {
	OTHER = 0,
	SINGLE_TARGET_DAMAGE = 1,
	AOE_DAMAGE = 2,
	BUFF = 3,
	DEBUFF = 4,
	HEAL = 5
}

@export var moveName: String = ''
@export var requiredLv: int = 1
@export var role: Role = Role.OTHER
@export_range(-100, 100) var power: int = 0 # negative power is healing, positive power is damage
@export var category: DmgCategory = DmgCategory.PHYSICAL
@export var targets: BattleCommand.Targets = BattleCommand.Targets.SELF
@export var statChanges: StatChanges = StatChanges.new()
@export var statusEffect: StatusEffect = null
@export var statusChance: float = 0.0
@export_multiline var description: String = ''
@export_multiline var moveLearnedText: String = ''

static func dmg_category_to_string(c: DmgCategory) -> String:
	match c:
		DmgCategory.PHYSICAL:
			return 'Physical'
		DmgCategory.MAGIC:
			return 'Magic'
		DmgCategory.AFFINITY:
			return 'Affinity'
	return 'UNKNOWN'

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
	i_moveName = '',
	i_requiredLv = 1,
	i_power = 0,
	i_category = DmgCategory.PHYSICAL,
	i_targets = BattleCommand.Targets.SELF,
	i_statusEffect = null,
	i_statusChance = 0.0,
	i_statChanges = StatChanges.new(),
	i_description = '',
	i_moveLearnedText = '',
	
):
	moveName = i_moveName
	requiredLv = i_requiredLv
	power = i_power
	category = i_category
	targets = i_targets
	statusEffect = i_statusEffect
	statusChance = i_statusChance
	statChanges = i_statChanges
	description = i_description
	moveLearnedText = i_moveLearnedText
	
