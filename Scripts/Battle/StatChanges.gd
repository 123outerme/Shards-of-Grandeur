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
