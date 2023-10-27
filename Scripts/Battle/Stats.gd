extends Resource
class_name Stats

enum Category {
	PHYS_ATK = 0,
	MAGIC_ATK = 1,
	RESISTANCE = 2,
	AFFINITY = 3,
	SPEED = 4
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

@export_category("Stats - Equipment")
@export var equippedWeapon: Weapon = null
@export var equippedArmor: Armor = null

@export_category("Stats - Moves")
@export var moves: Array[Move] = [load("res://GameData/Moves/slice.tres") as Move]
@export var movepool: Array[Move] = [load("res://GameData/Moves/slice.tres") as Move]

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
	i_weapon = null,
	i_armor = null,
	i_moves: Array[Move] = [load("res://GameData/Moves/slice.tres") as Move],
	i_movepool: Array[Move] = [load("res://GameData/Moves/slice.tres") as Move],
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
	equippedWeapon = i_weapon
	equippedArmor = i_armor
	moves = i_moves
	movepool = i_movepool

static func calculate_base_stats(oldStats: Stats, newLv: int) -> Stats:
	var stat = calculate_stat_category(newLv)
	return Stats.new(
		oldStats.displayName,
		oldStats.saveName,
		newLv,
		oldStats.experience,
		calculate_max_hp(newLv),
		stat,
		stat,
		stat,
		stat,
		stat,
		oldStats.equippedWeapon,
		oldStats.equippedArmor,
		oldStats.moves,
		oldStats.movepool,
	)

static func calculate_max_hp(lv: int) -> int:
	var hp = 50
	for i in range(lv):
		hp += hp_gain(i)
	return hp
	
static func calculate_stat_category(lv: int) -> int:
	var stat = 1
	for i in range(lv):
		stat += stat_gain(i)
	return stat

static func calculate_floating_stat_pts(lv: int) -> int:
	var pts = 0
	for i in range(lv):
		pts += floating_stat_pt_gain(i)
	return pts

static func hp_gain(lv: int) -> int:
	return lv + 2
	
static func stat_gain(lv: int):
	return round(0.1 * lv + 1)
	
static func get_required_exp(lv: int) -> int:
	return round( 1.1*pow(lv - 1, 2) + 25*(lv - 1) + 100 )
	
static func floating_stat_pt_gain(lv: int) -> int:
	return floor(0.1 * lv + 1)

func add_exp(addingExp: int) -> int:
	var newLevel: int = level
	experience += addingExp
	while experience > Stats.get_required_exp(newLevel):
		experience -= Stats.get_required_exp(newLevel)
		newLevel += 1 # increment and check if requirement is satisfied
	var levelDiff: int = newLevel - level
	#print(levelDiff, ' diff. ', newLevel, ' vs ', level)
	level_up(levelDiff)
	return levelDiff # return the difference

func level_up(newLvs: int):
	var stat = 0
	var pts = 0
	for i in range(1, newLvs + 1):
		level += 1 # add one level every loop iteration to add a total of `newLvs` levels
		maxHp += Stats.hp_gain(level)
		stat += Stats.stat_gain(level)
		pts += Stats.floating_stat_pt_gain(level)
	physAttack += stat
	magicAttack += stat
	resistance += stat
	affinity += stat
	speed += stat
	statPts += pts

func get_stat_for_dmg_category(category: Move.DmgCategory) -> int:
	if category == Move.DmgCategory.PHYSICAL:
		return physAttack
	if category == Move.DmgCategory.MAGIC:
		return magicAttack
	return affinity

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
	equippedWeapon = s.equippedWeapon
	equippedArmor = s.equippedArmor
	moves = s.moves
	movepool = s.movepool
