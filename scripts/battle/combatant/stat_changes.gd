extends Resource
class_name StatChanges

@export_category('Numeric Increases')
@export var physAttackIncrease: int = 0
@export var magicAttackIncrease: int = 0
@export var affinityIncrease: int = 0
@export var resistanceIncrease: int = 0
@export var speedIncrease: int = 0

@export_category('Percentage Multipliers')
@export var physAttackMultiplier: float = 1.0
@export var magicAttackMultiplier: float = 1.0
@export var affinityMultiplier: float = 1.0
@export var resistanceMultiplier: float = 1.0
@export var speedMultiplier: float = 1.0

func _init(
	i_physM = 1.0,
	i_magicM = 1.0,
	i_affinityM = 1.0,
	i_resistanceM = 1.0,
	i_speedM = 1.0,
	i_physN = 0,
	i_magicN = 0,
	i_affinityN = 0,
	i_resistanceN = 0,
	i_speedN = 0,
):
	physAttackIncrease = i_physN
	magicAttackIncrease = i_magicN
	affinityIncrease = i_affinityN
	resistanceIncrease = i_resistanceN
	speedIncrease = i_speedN
	physAttackMultiplier = i_physM
	magicAttackMultiplier = i_magicM
	affinityMultiplier = i_affinityM
	resistanceMultiplier = i_resistanceM
	speedMultiplier = i_speedM

func reset():
	physAttackIncrease = 0
	magicAttackIncrease = 0
	affinityIncrease = 0
	resistanceIncrease = 0
	speedIncrease = 0
	physAttackMultiplier = 1.0
	magicAttackMultiplier = 1.0
	affinityMultiplier = 1.0
	resistanceMultiplier = 1.0
	speedMultiplier = 1.0

func stack(changes: StatChanges):
	if changes == null:
		return
	physAttackIncrease += changes.physAttackIncrease
	magicAttackIncrease += changes.magicAttackIncrease
	affinityIncrease += changes.affinityIncrease
	resistanceIncrease += changes.resistanceIncrease
	speedIncrease += changes.speedIncrease
	
	physAttackMultiplier += changes.physAttackMultiplier - 1.0
	magicAttackMultiplier += changes.magicAttackMultiplier - 1.0
	affinityMultiplier += changes.affinityMultiplier - 1.0
	resistanceMultiplier += changes.resistanceMultiplier - 1.0
	speedMultiplier += changes.speedMultiplier - 1.0

func subtract(changes: StatChanges) -> StatChanges:
	var newChanges = self.duplicate()
	if changes != null:
		newChanges.physAttackIncrease -= changes.physAttackIncrease
		newChanges.magicAttackIncrease -= changes.magicAttackIncrease
		newChanges.affinityIncrease -= changes.affinityIncrease
		newChanges.resistanceIncrease -= changes.resistanceIncrease
		newChanges.speedIncrease -= changes.speedIncrease
	
		newChanges.physAttackMultiplier -= changes.physAttackMultiplier - 1.0
		newChanges.magicAttackMultiplier -= changes.magicAttackMultiplier - 1.0
		newChanges.affinityMultiplier -= changes.affinityMultiplier - 1.0
		newChanges.resistanceMultiplier -= changes.resistanceMultiplier - 1.0
		newChanges.speedMultiplier -= changes.speedMultiplier - 1.0
	
	return newChanges

func times(x: float):
	physAttackIncrease = roundi(physAttackIncrease * x)
	magicAttackIncrease = roundi(magicAttackIncrease * x)
	affinityIncrease = roundi(affinityIncrease * x)
	resistanceIncrease = roundi(resistanceIncrease * x)
	speedIncrease = roundi(speedIncrease * x)
	
	physAttackMultiplier = (physAttackMultiplier - 1.0) * x + 1
	magicAttackMultiplier = (magicAttackMultiplier - 1.0) * x + 1
	affinityMultiplier = (affinityMultiplier - 1.0) * x + 1
	resistanceMultiplier = (resistanceMultiplier - 1.0) * x + 1
	speedMultiplier = (speedMultiplier - 1.0) * x + 1

func equals(changes: StatChanges) -> bool:
	if changes == null:
		return false
	
	if physAttackIncrease != changes.physAttackIncrease:
		return false
	if magicAttackIncrease != changes.magicAttackIncrease:
		return false
	if affinityIncrease != changes.affinityIncrease:
		return false
	if resistanceIncrease != changes.resistanceIncrease:
		return false
	if speedIncrease != changes.speedIncrease:
		return false
	
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
	physAttackIncrease -= changes.physAttackIncrease
	magicAttackIncrease -= changes.magicAttackIncrease
	affinityIncrease -= changes.affinityIncrease
	resistanceIncrease -= changes.resistanceIncrease
	speedIncrease -= changes.speedIncrease
	
	physAttackMultiplier -= changes.physAttackMultiplier - 1.0
	magicAttackMultiplier -= changes.magicAttackMultiplier - 1.0
	affinityMultiplier -= changes.affinityMultiplier - 1.0
	resistanceMultiplier -= changes.resistanceMultiplier - 1.0
	speedMultiplier -= changes.speedMultiplier - 1.0

func apply(s: Stats) -> Stats:
	var newStats = s.copy()
	newStats.physAttack += physAttackIncrease
	newStats.magicAttack += magicAttackIncrease
	newStats.affinity += affinityIncrease
	newStats.resistance += resistanceIncrease
	newStats.speed += speedIncrease
	
	newStats.physAttack = roundi(newStats.physAttack * physAttackMultiplier)
	newStats.magicAttack = roundi(newStats.magicAttack * magicAttackMultiplier)
	newStats.affinity = roundi(newStats.affinity * affinityMultiplier)
	newStats.resistance = roundi(newStats.resistance * resistanceMultiplier)
	newStats.speed = roundi(newStats.speed * speedMultiplier)
	return newStats

func has_stat_changes() -> bool:
	return physAttackIncrease != 0 \
			or magicAttackIncrease != 0 \
			or affinityIncrease != 0 \
			or resistanceIncrease != 0 \
			or speedIncrease != 0 \
			or physAttackMultiplier != 1.0 \
			or magicAttackMultiplier != 1.0 \
			or resistanceMultiplier != 1.0 \
			or affinityMultiplier != 1.0 \
			or speedMultiplier != 1.0

func get_phys_atk_multiplier() -> StatMultiplierText:
	return StatMultiplierText.new('Phys Atk', physAttackIncrease, physAttackMultiplier)
	
func get_magic_atk_multiplier() -> StatMultiplierText:
	return StatMultiplierText.new('Magic Atk', magicAttackIncrease, magicAttackMultiplier)

func get_affinity_multiplier() -> StatMultiplierText:
	return StatMultiplierText.new('Affinity', affinityIncrease, affinityMultiplier)

func get_resistance_multiplier() -> StatMultiplierText:
	return StatMultiplierText.new('Resistance', resistanceIncrease, resistanceMultiplier)

func get_speed_multiplier() -> StatMultiplierText:
	return StatMultiplierText.new('Speed', speedIncrease, speedMultiplier)

func get_multipliers_text() -> Array[StatMultiplierText]:
	var texts: Array[StatMultiplierText] = []
	
	if physAttackIncrease != 0 or physAttackMultiplier != 1.0:
		texts.append(get_phys_atk_multiplier())
	
	if magicAttackIncrease != 0 or magicAttackMultiplier != 1.0:
		texts.append(get_magic_atk_multiplier())
	
	if affinityIncrease != 0 or affinityMultiplier != 1.0:
		texts.append(get_affinity_multiplier())
	
	if resistanceIncrease != 0 or resistanceMultiplier != 1.0:
		texts.append(get_resistance_multiplier())
	
	if speedIncrease != 0 or speedMultiplier != 1.0:
		texts.append(get_speed_multiplier())
	
	return texts
