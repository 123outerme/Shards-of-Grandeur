extends Resource
class_name Move

enum Targets {
	SELF = 0, # only self is a valid target
	NON_SELF_ALLY = 1, # only valid target is an ally that is not the user
	ALLY = 2, # single-target one combatant on player's side
	ALL_ALLIES = 3, # multi-target all allies on player's side
	ENEMY = 4, # single-target one combatant on enemy side
	ALL_ENEMIES = 5, # multi-target one combatant on enemy side
}

enum DmgCategory {
	PHYSICAL = 0,
	MAGIC = 1
}

@export var moveName: String = ''
@export_range(-100, 100) var power: int = 0 # negative power is healing, positive power is damage
@export var category: DmgCategory = DmgCategory.PHYSICAL
@export var targets: Targets = Targets.SELF
@export var statusEffect: StatusEffect = null
@export var statusChance: float = 0.0
@export var statChanges: StatChanges = StatChanges.new()

func _init(
	i_moveName = '',
	i_power = 0,
	i_category = DmgCategory.PHYSICAL,
	i_targets = Targets.SELF,
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
