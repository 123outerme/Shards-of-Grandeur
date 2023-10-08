extends Resource
class_name Combatant

@export_category("Combatant - Sprite")
@export var sprite: Texture2D = null

@export_category("Combatant - Stats")
@export var stats: Stats = Stats.new()
@export var currentHp: int = -1
@export var statChanges: StatChanges = StatChanges.new()
@export var statusEffect: StatusEffect = null

@export_category("Combatant - Encounter")
@export var equipmentTable: Array[WeightedEquipment] = []
@export var teamTable: Array[WeightedString] = []
# NOTE: having a weighted combatant caused recursion errors, so this is the workaround
@export var dropTable: Array[WeightedReward] = []
@export var innateStatCategories: Array[Stats.Category] = []

@export_category("Combatant - In Battle")
@export var command: BattleCommand = null
@export var downed: bool = false

static func load_combatant_resource(saveName: String) -> Combatant:
	var combatant: Combatant = load("res://GameData/Combatants/" + saveName + ".tres")
	# TODO level up combatant to proper level if necessary
	if combatant.currentHp == -1:
		combatant.currentHp = combatant.stats.maxHp # load max HP if combatant was loaded from resource
	return combatant

func _init(
	i_stats = Stats.new(),
	i_curHp = -1,
	i_statChanges = StatChanges.new(),
	i_statusEffect = null,
	i_sprite = null,
	i_equipmentTable: Array[WeightedEquipment] = [],
	i_teamTable: Array[WeightedString] = [],
	i_dropTable: Array[WeightedReward] = [],
	i_innateStats: Array[Stats.Category] = [],
):
	stats = i_stats
	if i_curHp != -1:
		currentHp = i_curHp
	else:
		currentHp = stats.maxHp
	statChanges = i_statChanges
	statusEffect = i_statusEffect
	sprite = i_sprite
	equipmentTable = i_equipmentTable
	teamTable = i_teamTable
	dropTable = i_dropTable
	innateStatCategories = i_innateStats

func copy() -> Combatant:
	return Combatant.new(
		stats.copy(),
		currentHp,
		statChanges,
		statusEffect,
		sprite,
		equipmentTable,
		teamTable,
		dropTable,
		innateStatCategories,
	)

func disp_name() -> String:
	return stats.displayName

func save_name() -> String:
	return stats.saveName

func update_downed():
	downed = currentHp <= 0

func level_up_nonplayer(newLv: int):
	var lvDiff: int = newLv - stats.level
	if lvDiff > 0:
		stats.level_up(lvDiff)
		currentHp = stats.maxHp
		# if there are innate stat categories to allocate to
		if len(innateStatCategories) > 0:
			while stats.statPts > 0:
				# randomly allocate stats to the innate stat categories
				var randomCategory: Stats.Category = innateStatCategories[randi_range(0, len(innateStatCategories))]
				if randomCategory == Stats.Category.PHYS_ATK:
					stats.physAttack += 1
				if randomCategory == Stats.Category.MAGIC_ATK:
					stats.magicAttack += 1
				if randomCategory == Stats.Category.RESISTANCE:
					stats.resistance += 1
				if randomCategory == Stats.Category.AFFINITY:
					stats.affinity += 1
				if randomCategory == Stats.Category.SPEED:
					stats.speed += 1
				stats.statPts -= 1
	else:
		print("level up nonplayer err: level diff is negative")
