extends Resource
class_name Stats

@export_category("Stats - Statline")
@export var level: int = 1
@export var maxHp: int = 20
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
@export var moves: Array = ["Slice"]
@export var movepool: Array = ["Slice"]

func _init(
	i_level = 1,
	i_maxHp = 50,
	i_physAttack = 1,
	i_magicAttack = 1,
	i_resistance = 1,
	i_affinity = 1,
	i_speed = 1,
	i_statPts = 0,
	i_weapon = null,
	i_armor = null,
	i_moves = ["Slice"],
	i_movepool = ["Slice"]
):
	level = i_level
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

static func calculate_base_stats(lv: int) -> Stats:
	var stat = calculate_stat_category(lv)
	return Stats.new(
		lv,
		calculate_max_hp(lv),
		stat,
		stat,
		stat,
		stat,
		stat,
	)

static func calculate_max_hp(lv: int) -> int:
	var hp = 20
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

func level_up(newLvs: int):
	var stat = 0
	var pts = 0
	for i in range(1, newLvs + 1):
		maxHp += hp_gain(level + i)
		stat += stat_gain(level + i)
		pts += floating_stat_pt_gain(level + i)
	physAttack += stat
	magicAttack += stat
	resistance += stat
	affinity += stat
	speed += stat
	statPts += pts
