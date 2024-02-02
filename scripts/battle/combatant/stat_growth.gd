extends Resource
class_name StatGrowth

@export var initialMaxHp: int = 50
@export var hpGrowth: float = 1
@export var physAtkGrowth: float = 1
@export var magicAtkGrowth: float = 1
@export var affinityGrowth: float = 1
@export var resistanceGrowth: float = 1
@export var speedGrowth: float = 1

static func hp_gain(lv: int) -> int:
	return lv + 2
	
static func stat_gain(lv: int) -> int:
	return floori(0.1 * lv + 1)

func _init(
	i_hpGrowth = 1,
	i_physAtkGrowth = 1,
	i_magicAtkGrowth = 1,
	i_affinityGrowth = 1,
	i_resistanceGrowth = 1,
	i_speedGrowth = 1,
):
	hpGrowth = i_hpGrowth
	physAtkGrowth = i_physAtkGrowth
	magicAtkGrowth = i_magicAtkGrowth
	affinityGrowth = i_affinityGrowth
	resistanceGrowth = i_resistanceGrowth
	speedGrowth = i_speedGrowth

func get_stat_growth(category: Stats.Category) -> float:
	var growth: float = 0
	match category:
		Stats.Category.HP:
			growth = hpGrowth
		Stats.Category.PHYS_ATK:
			growth = physAtkGrowth
		Stats.Category.MAGIC_ATK:
			growth = magicAtkGrowth
		Stats.Category.AFFINITY:
			growth = affinityGrowth
		Stats.Category.RESISTANCE:
			growth = resistanceGrowth
		Stats.Category.SPEED:
			growth = speedGrowth
	
	return growth

func calculate_max_hp(level: int) -> int:
	var maxHp: float = initialMaxHp
	for i in range(1, level):
		maxHp += hpGrowth * StatGrowth.hp_gain(i + 1)
	return roundi(maxHp)

func calculate_stat_category(level: int, category: Stats.Category) -> int:
	var stat: float = 1
	var growth = get_stat_growth(category)
	for i in range(1, level):
		stat += growth * StatGrowth.stat_gain(i + 1)
	return roundi(stat)
