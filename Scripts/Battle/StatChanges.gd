extends Resource
class_name StatChanges

@export var physAttackMultiplier: float = 1.0
@export var magicAttackMultiplier: float = 1.0
@export var resistanceMultiplier: float = 1.0
@export var affinityMultiplier: float = 1.0
@export var speedMultiplier: float = 1.0

func _init(
	i_phys = 1.0,
	i_magic = 1.0,
	i_resistance = 1.0,
	i_affinity = 1.0,
	i_speed = 1.0,
):
	physAttackMultiplier = i_phys
	magicAttackMultiplier = i_magic
	resistanceMultiplier = i_resistance
	affinityMultiplier = i_affinity
	speedMultiplier = i_speed

func stack(changes: StatChanges):
	physAttackMultiplier += changes.physAttackMultiplier
	magicAttackMultiplier += changes.magicAttackMultiplier
	resistanceMultiplier += changes.resistanceMultiplier
	affinityMultiplier += changes.affinityMultiplier
	speedMultiplier += changes.speedMultiplier

func apply(s: Stats) -> Stats:
	var newStats = s.copy()
	newStats.physAttack *= physAttackMultiplier
	newStats.magicAttack *= magicAttackMultiplier
	newStats.resistance *= resistanceMultiplier
	newStats.affinity *= affinityMultiplier
	newStats.speed *= speedMultiplier
	return newStats
