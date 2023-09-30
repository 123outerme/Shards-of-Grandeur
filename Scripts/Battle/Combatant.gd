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

func _init(
	i_stats = Stats.new(),
	i_curHp = -1,
	i_statChanges = StatChanges.new(),
	i_statusEffect = null,
	i_sprite = null,
):
	sprite = i_sprite
	stats = i_stats
	currentHp = i_curHp
	statChanges = i_statChanges
	statusEffect = i_statusEffect
