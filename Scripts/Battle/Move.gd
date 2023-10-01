extends Resource
class_name Move

enum DmgCategory {
	PHYSICAL = 0,
	MAGIC = 1
}

@export var moveName: String = ''
@export_range(-100, 100) var power: int = 0 # negative power is healing, positive power is damage
@export var category: DmgCategory = DmgCategory.PHYSICAL
@export var targets: BattleCommand.Targets = BattleCommand.Targets.SELF
@export var statusEffect: StatusEffect = null
@export var statusChance: float = 0.0
@export var statChanges: StatChanges = StatChanges.new()

func _init(
	i_moveName = '',
	i_power = 0,
	i_category = DmgCategory.PHYSICAL,
	i_targets = BattleCommand.Targets.SELF,
	i_statusEffect = null,
	i_statusChance = 0.0,
	i_statChanges = StatChanges.new(),
	
):
	moveName = i_moveName
	power = i_power
	category = i_category
	targets = i_targets
	statusEffect = i_statusEffect
	statusChance = i_statusChance
	statChanges = i_statChanges
