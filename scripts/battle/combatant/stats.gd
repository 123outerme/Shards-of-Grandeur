extends Resource
class_name Stats

enum Category {
	PHYS_ATK = 0,
	MAGIC_ATK = 1,
	RESISTANCE = 2,
	AFFINITY = 3,
	SPEED = 4,
	HP = 5,
}

@export_category("Stats - Name")
@export var displayName: String = 'Entity'
@export var saveName: String = 'uninstantiated_entity'

@export_category("Stats - Statline")
@export var level: int = 1
@export var experience: int = 0
@export var maxHp: int = 50
@export var physAttack: int = 1
@export var magicAttack: int = 1
@export var resistance: int = 1
@export var affinity: int = 1
@export var speed: int = 1
@export var statPts: int = 0
@export var statGrowth: StatGrowth = StatGrowth.new()

@export_category("Stats - Equipment")
@export var equippedWeapon: Weapon = null
@export var equippedArmor: Armor = null

@export_category("Stats - Moves")
@export var moves: Array[Move] = []
@export var movepool: MovePool = MovePool.new([load("res://gamedata/moves/slice/slice.tres") as Move])

func _init(
	i_displayName = 'Entity',
	i_saveName = 'uninstantiated_entity',
	i_level = 1,
	i_exp = 0,
	i_maxHp = 50,
	i_physAttack = 1,
	i_magicAttack = 1,
	i_resistance = 1,
	i_affinity = 1,
	i_speed = 1,
	i_statPts = 0,
	i_statGrowth = StatGrowth.new(),
	i_weapon = null,
	i_armor = null,
	i_moves: Array[Move] = [load("res://gamedata/moves/slice/slice.tres") as Move],
	i_movepool: MovePool = MovePool.new([load("res://gamedata/moves/slice/slice.tres") as Move]),
):
	displayName = i_displayName
	saveName = i_saveName
	level = i_level
	experience = i_exp
	maxHp = i_maxHp
	physAttack = i_physAttack
	magicAttack = i_magicAttack
	resistance = i_resistance
	affinity = i_affinity
	speed = i_speed
	statPts = i_statPts
	statGrowth = i_statGrowth
	equippedWeapon = i_weapon
	equippedArmor = i_armor
	moves = i_moves
	movepool = i_movepool

static func calculate_base_stats(oldStats: Stats, newLv: int) -> Stats:
	var baseStats = Stats.new(
		oldStats.displayName,
		oldStats.saveName,
		1,
		oldStats.experience,
		oldStats.statGrowth.initialMaxHp,
		1,
		1,
		1,
		1,
		1,
		0,
		oldStats.statGrowth.duplicate(false),
		oldStats.equippedWeapon,
		oldStats.equippedArmor,
		oldStats.moves,
		oldStats.movepool,
	)
	baseStats.level_up(newLv - 1)
	return baseStats
	
static func calculate_floating_stat_pts(lv: int) -> int:
	var pts = 0
	for i in range(lv):
		pts += floating_stat_pt_gain(i)
	return pts
	
static func floating_stat_pt_gain(lv: int) -> int:
	return floor(0.1 * lv + 1)

static func get_required_exp(lv: int) -> int:
	return round( 1.1*pow(lv - 1, 2) + 25*(lv - 1) + 100 )

func add_exp(addingExp: int) -> int:
	var newLevel: int = level
	experience += addingExp
	while experience >= Stats.get_required_exp(newLevel):
		experience -= Stats.get_required_exp(newLevel)
		newLevel += 1 # increment and check if requirement is satisfied
	var levelDiff: int = newLevel - level
	level_up(levelDiff)
	return levelDiff # return the difference

func level_up(newLvs: int):
	if newLvs <= 0:
		return
	
	var pts = 0
	for i in range(1, newLvs + 1):
		level += 1 # add one level every loop iteration to add a total of `newLvs` levels
		pts += Stats.floating_stat_pt_gain(level)
	maxHp = statGrowth.calculate_max_hp(level)
	physAttack += statGrowth.calculate_stat_category(level, Category.PHYS_ATK) - statGrowth.calculate_stat_category(level - newLvs, Category.PHYS_ATK)
	magicAttack += statGrowth.calculate_stat_category(level, Category.MAGIC_ATK) - statGrowth.calculate_stat_category(level - newLvs, Category.MAGIC_ATK)
	affinity += statGrowth.calculate_stat_category(level, Category.AFFINITY) - statGrowth.calculate_stat_category(level - newLvs, Category.AFFINITY)
	resistance += statGrowth.calculate_stat_category(level, Category.RESISTANCE) - statGrowth.calculate_stat_category(level - newLvs, Category.RESISTANCE)
	speed += statGrowth.calculate_stat_category(level, Category.SPEED) - statGrowth.calculate_stat_category(level - newLvs, Category.SPEED)
	statPts += pts

func set_level(lv: int):
	level = lv
	var pts = 0
	for i in range(2, level + 1):
		pts += Stats.floating_stat_pt_gain(i)
	maxHp = statGrowth.calculate_max_hp(level)
	physAttack = statGrowth.calculate_stat_category(level, Category.PHYS_ATK) 
	magicAttack = statGrowth.calculate_stat_category(level, Category.MAGIC_ATK)
	affinity = statGrowth.calculate_stat_category(level, Category.AFFINITY)
	resistance = statGrowth.calculate_stat_category(level, Category.RESISTANCE)
	speed = statGrowth.calculate_stat_category(level, Category.SPEED)
	statPts = pts

func is_item_equipped(item: Item):
	return equippedWeapon == item or equippedArmor == item

func equip_item(item: Item):
	if item is Weapon:
		equippedWeapon = item
	elif item is Armor:
		equippedArmor = item

func unequip_item(item: Item):
	if item == equippedWeapon:
		equippedWeapon = null
	elif item == equippedArmor:
		equippedArmor = null

func add_move_to_pool(move: Move):
	movepool.pool.append(move)
	if len(moves) < 4:
		moves.append(move)
	else:
		for i in range(4):
			if moves[i] == null:
				moves[i] = move
				break

func get_stat_for_dmg_category(category: Move.DmgCategory) -> int:
	if category == Move.DmgCategory.PHYSICAL:
		return physAttack
	if category == Move.DmgCategory.MAGIC:
		return magicAttack
	return affinity

func get_total_gained_stat_points() -> int:
	var pts: int = 0
	for i in range(2, level + 1):
		pts += Stats.floating_stat_pt_gain(i)
	return pts

func get_stat_total():
	return physAttack + magicAttack + affinity + resistance + speed + statPts

func reset_stat_points():
	save_from_object(Stats.calculate_base_stats(self, level))

func is_stat_total_valid() -> bool:
	# if floating stat points are negative, this is cheated! (or bugged I guess)
	if statPts < 0:
		return false
	
	var newStats: Stats = Stats.calculate_base_stats(self, level)
	
	# if stat totals or max HP values don't match, not valid
	if not (get_stat_total() == newStats.get_stat_total() and maxHp == newStats.maxHp):
		return false
	
	# if a base stat is ABOVE the current stat, not valid
	if newStats.physAttack > physAttack or newStats.magicAttack > magicAttack or \
			newStats.affinity > affinity or newStats.resistance > resistance or \
			newStats.speed > speed:
		return false
	
	# from here: attempt to "allocate" stat points to match the current stats
	# can't give floating stat point "credit" here, since none of the base stats are greater by this point
	newStats.statPts -= physAttack - newStats.physAttack
	newStats.statPts -= magicAttack - newStats.magicAttack
	newStats.statPts -= affinity - newStats.affinity
	newStats.statPts -= resistance - newStats.resistance
	newStats.statPts -= speed - newStats.speed
	
	# If we don't have the same amount of floating stat points now, not valid
	if newStats.statPts != statPts:
		return false
	
	return true

func copy() -> Stats:
	var newStats = Stats.new()
	newStats.save_from_object(self)
	return newStats

func save_from_object(s: Stats):
	displayName = s.displayName
	saveName = s.saveName
	level = s.level
	experience = s.experience
	maxHp = s.maxHp
	physAttack = s.physAttack
	magicAttack = s.magicAttack
	resistance = s.resistance
	affinity = s.affinity
	speed = s.speed
	statPts = s.statPts
	statGrowth = s.statGrowth
	equippedWeapon = s.equippedWeapon
	equippedArmor = s.equippedArmor
	moves = s.moves.duplicate(false)
	movepool = s.movepool

func print_stats() -> String:
	return 'Lv: ' + String.num(level) + '\nHP: ' + String.num(maxHp) + '\nPhys: ' + \
			String.num(physAttack) + '\nMagic: ' + String.num(magicAttack) + '\nAffinity: ' + \
			String.num(affinity) + '\nResistance: ' + String.num(resistance) + \
			'\nSpeed: ' + String.num(speed)
