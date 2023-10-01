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
