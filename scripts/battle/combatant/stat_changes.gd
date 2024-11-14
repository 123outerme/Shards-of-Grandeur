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

@export var elementMultipliers: Array[ElementMultiplier] = []

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
	i_elementMults: Array[ElementMultiplier] = [],
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
	elementMultipliers = i_elementMults

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
	elementMultipliers = []

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
	
	for changesMult: ElementMultiplier in changes.elementMultipliers:
		var found: bool = false
		for mult: ElementMultiplier in elementMultipliers:
			if mult.element == changesMult.element:
				mult.multiplier += changesMult.multiplier - 1.0
				if mult.multiplier == 1.0:
					# remove the 1x multiplier
					var idx: int = elementMultipliers.find(mult)
					if idx != -1:
						elementMultipliers.remove_at(idx)
				found = true
		if not found:
			var newMult: ElementMultiplier = changesMult.duplicate()
			if newMult.multiplier != 1.0:
				elementMultipliers.append(newMult)

func subtract(changes: StatChanges) -> StatChanges:
	var newChanges: StatChanges = copy()
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
		
		for changesMult: ElementMultiplier in changes.elementMultipliers:
			var found: bool = false
			for mult: ElementMultiplier in newChanges.elementMultipliers:
				if mult.element == changesMult.element:
					mult.multiplier -= changesMult.multiplier - 1.0
					if mult.multiplier == 1.0:
						# remove the 1x multiplier
						var idx: int = newChanges.elementMultipliers.find(mult)
						if idx != -1:
							newChanges.elementMultipliers.remove_at(idx)
					found = true
			if not found:
				var newMult: ElementMultiplier = changesMult.duplicate()
				newMult.multiplier -= newMult.multiplier - 1.0
				# only add the multiplier if it's not 1x
				if newMult.multiplier != 1.0:
					newChanges.elementMultipliers.append(newMult)
	
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
	
	for mult: ElementMultiplier in elementMultipliers:
		mult.multiplier = (mult.multiplier - 1.0) * x + 1

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
	
	if len(elementMultipliers) != len(changes.elementMultipliers):
		return false
	
	for changesMult: ElementMultiplier in changes.elementMultipliers:
		var found = false
		for mult: ElementMultiplier in elementMultipliers:
			if mult.element == changesMult.element:
				found = true
				if mult.multiplier != mult.multiplier:
					return false
		if not found and changesMult.multiplier != 1.0:
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
	
	for changesMult: ElementMultiplier in changes.elementMultipliers:
		var found: bool = false
		for mult: ElementMultiplier in elementMultipliers:
			if mult.element == changesMult.element:
				mult.multiplier -= changesMult.multiplier - 1.0
				if mult.multiplier == 1.0:
					# remove the 1x multiplier
					var idx: int = elementMultipliers.find(mult)
					if idx != -1:
						elementMultipliers.remove_at(idx)
				found = true
		if not found:
			var newMult: ElementMultiplier = changesMult.duplicate()
			newMult.multiplier -= newMult.multiplier - 1.0
			if newMult.multiplier != 1.0:
				elementMultipliers.append(newMult)

func apply(s: Stats) -> Stats:
	var newStats = s.copy()
	newStats.physAttack += physAttackIncrease
	newStats.magicAttack += magicAttackIncrease
	newStats.affinity += affinityIncrease
	newStats.resistance += resistanceIncrease
	newStats.speed += speedIncrease
	
	# factor in multipliers, don't let any stat go below 1 stat point
	newStats.physAttack = max(1, roundi(newStats.physAttack * physAttackMultiplier))
	newStats.magicAttack = max(1, roundi(newStats.magicAttack * magicAttackMultiplier))
	newStats.affinity = max(1, roundi(newStats.affinity * affinityMultiplier))
	newStats.resistance = max(1, roundi(newStats.resistance * resistanceMultiplier))
	newStats.speed = max(1, roundi(newStats.speed * speedMultiplier))
	
	# element multipliers are not stored in the stats object, so ignore those
	return newStats

func get_element_multiplier(e: Move.Element) -> float:
	for mult: ElementMultiplier in elementMultipliers:
		if mult.element == e:
			return mult.multiplier
	
	return 1.0

func get_attack_percent_boost_for_category(c: Move.DmgCategory) -> float:
	match c:
		Move.DmgCategory.PHYSICAL:
			return physAttackMultiplier
		Move.DmgCategory.MAGIC:
			return magicAttackMultiplier
		Move.DmgCategory.AFFINITY:
			return affinityMultiplier
	return 1

func get_attack_pt_boost_for_category(c: Move.DmgCategory) -> int:
	match c:
		Move.DmgCategory.PHYSICAL:
			return physAttackIncrease
		Move.DmgCategory.MAGIC:
			return magicAttackIncrease
		Move.DmgCategory.AFFINITY:
			return affinityIncrease
	return 0

func sum_weighted_elemental_multipliers(positiveWeight: float = 1.0, negativeWeight: float = 1.0) -> float:
	var sum: float = 0
	for mult: ElementMultiplier in elementMultipliers:
		if mult.multiplier > 1.0:
			sum += (mult.multiplier - 1.0) * positiveWeight
		elif mult.multiplier < 1.0:
			sum += (mult.multiplier - 1.0) * negativeWeight
	
	return sum

func has_stat_changes() -> bool:
	# check if any element multipliers exist that aren't 1x. If there is at least one, this obj has stat changes
	for mult: ElementMultiplier in elementMultipliers:
		if mult.multiplier != 1.0:
			return true
	
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

func get_multiplier_for_stat_category(category: Stats.Category) -> StatMultiplierText:
	match category:
		Stats.Category.PHYS_ATK:
			return get_phys_atk_multiplier()
		Stats.Category.MAGIC_ATK:
			return get_magic_atk_multiplier()
		Stats.Category.AFFINITY:
			return get_affinity_multiplier()
		Stats.Category.RESISTANCE:
			return get_resistance_multiplier()
		Stats.Category.SPEED:
			return get_speed_multiplier()
	return null

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

func get_element_multiplier_texts() -> Array[StatMultiplierText]:
	var texts: Array[StatMultiplierText] = []
	for mult: ElementMultiplier in elementMultipliers:
		if mult.multiplier != 1.0:
			texts.append( \
				StatMultiplierText.new(Move.element_to_string(mult.element) + ' Dmg', 0, mult.multiplier) \
			)
	return texts

func get_stat_multiplier_texts() -> Array[StatMultiplierText]:
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

func get_multipliers_text() -> Array[StatMultiplierText]:
	var texts: Array[StatMultiplierText] = []
	texts.append_array(get_stat_multiplier_texts())
	texts.append_array(get_element_multiplier_texts())

	return texts

func copy() -> StatChanges:
	var newChanges: StatChanges = StatChanges.new()
	newChanges.stack(self)
	return newChanges
