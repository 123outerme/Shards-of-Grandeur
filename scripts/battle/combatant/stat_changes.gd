extends Resource
class_name StatChanges

@export var physAttackMultiplier: float = 1.0
@export var magicAttackMultiplier: float = 1.0
@export var affinityMultiplier: float = 1.0
@export var resistanceMultiplier: float = 1.0
@export var speedMultiplier: float = 1.0

func _init(
	i_phys = 1.0,
	i_magic = 1.0,
	i_affinity = 1.0,
	i_resistance = 1.0,
	i_speed = 1.0,
):
	physAttackMultiplier = i_phys
	magicAttackMultiplier = i_magic
	affinityMultiplier = i_affinity
	resistanceMultiplier = i_resistance
	speedMultiplier = i_speed

func reset():
	physAttackMultiplier = 1.0
	magicAttackMultiplier = 1.0
	affinityMultiplier = 1.0
	resistanceMultiplier = 1.0
	speedMultiplier = 1.0

func stack(changes: StatChanges):
	if changes == null:
		return
	physAttackMultiplier += changes.physAttackMultiplier - 1.0
	magicAttackMultiplier += changes.magicAttackMultiplier - 1.0
	affinityMultiplier += changes.affinityMultiplier - 1.0
	resistanceMultiplier += changes.resistanceMultiplier - 1.0
	speedMultiplier += changes.speedMultiplier - 1.0

func subtract(changes: StatChanges) -> StatChanges:
	var newChanges = self.duplicate()
	if changes != null:
		newChanges.physAttackMultiplier -= changes.physAttackMultiplier - 1.0
		newChanges.magicAttackMultiplier -= changes.magicAttackMultiplier - 1.0
		newChanges.affinityMultiplier -= changes.affinityMultiplier - 1.0
		newChanges.resistanceMultiplier -= changes.resistanceMultiplier - 1.0
		newChanges.speedMultiplier -= changes.speedMultiplier - 1.0
	
	return newChanges

func times(x: float):
	physAttackMultiplier = (physAttackMultiplier - 1.0) * x + 1
	magicAttackMultiplier = (magicAttackMultiplier - 1.0) * x + 1
	affinityMultiplier = (affinityMultiplier - 1.0) * x + 1
	resistanceMultiplier = (resistanceMultiplier - 1.0) * x + 1
	speedMultiplier = (speedMultiplier - 1.0) * x + 1

func equals(changes: StatChanges) -> bool:
	if physAttackMultiplier != changes.physAttackMultiplier:
		return false
	if magicAttackMultiplier != changes.magicAttackMultiplier:
		return false
	if affinityMultiplier != changes.affinityMultiplier:
		return false
	if resistanceMultiplier != changes.resistanceMultiplier:
		return false
	if speedMultiplier != changes.speedMultiplier:
		return false
	return true

func undo_changes(changes: StatChanges):
	if changes == null:
		return
	physAttackMultiplier -= changes.physAttackMultiplier - 1.0
	magicAttackMultiplier -= changes.magicAttackMultiplier - 1.0
	affinityMultiplier -= changes.affinityMultiplier - 1.0
	resistanceMultiplier -= changes.resistanceMultiplier - 1.0
	speedMultiplier -= changes.speedMultiplier - 1.0

func apply(s: Stats) -> Stats:
	var newStats = s.copy()
	newStats.physAttack = roundi(newStats.physAttack * physAttackMultiplier)
	newStats.magicAttack = roundi(newStats.magicAttack * magicAttackMultiplier)
	newStats.affinity = roundi(newStats.affinity * affinityMultiplier)
	newStats.resistance = roundi(newStats.resistance * resistanceMultiplier)
	newStats.speed *= roundi(newStats.speed * speedMultiplier)
	return newStats

func has_stat_changes() -> bool:
	return physAttackMultiplier != 1.0 \
			or magicAttackMultiplier != 1.0 \
			or resistanceMultiplier != 1.0 \
			or affinityMultiplier != 1.0 \
			or speedMultiplier != 1.0

func get_phys_atk_multiplier() -> StatMultiplierText:
	return StatMultiplierText.new('Phys Atk', physAttackMultiplier)
	
func get_magic_atk_multiplier() -> StatMultiplierText:
	return StatMultiplierText.new('Magic Atk', magicAttackMultiplier)

func get_affinity_multiplier() -> StatMultiplierText:
	return StatMultiplierText.new('Affinity', affinityMultiplier)

func get_resistance_multiplier() -> StatMultiplierText:
	return StatMultiplierText.new('Resistance', resistanceMultiplier)

func get_speed_multiplier() -> StatMultiplierText:
	return StatMultiplierText.new('Speed', speedMultiplier)

func get_multipliers_text() -> Array[StatMultiplierText]:
	var texts: Array[StatMultiplierText] = []
	
	if physAttackMultiplier != 1.0:
		texts.append(get_phys_atk_multiplier())
	
	if magicAttackMultiplier != 1.0:
		texts.append(get_magic_atk_multiplier())
	
	if affinityMultiplier != 1.0:
		texts.append(get_affinity_multiplier())
	
	if resistanceMultiplier != 1.0:
		texts.append(get_resistance_multiplier())
	
	if speedMultiplier != 1.0:
		texts.append(get_speed_multiplier())
	
	return texts
