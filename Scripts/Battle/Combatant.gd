extends Resource
class_name Combatant

@export_category("Combatant - Sprite")
@export var sprite: Texture2D = null

@export_category("Combatant - Stats")
@export var stats: Stats = Stats.new()
@export var currentHp: int = Stats.new().maxHp
@export var statChanges: StatChanges = StatChanges.new()
@export var statusEffect: StatusEffect = null

func _init(
	i_stats = Stats.new(),
	i_curHp = Stats.new().maxHp,
	i_statChanges = StatChanges.new(),
	i_statusEffect = null,
	i_sprite = null,
):
	sprite = i_sprite
	stats = i_stats
	currentHp = i_curHp
	statChanges = i_statChanges
	statusEffect = i_statusEffect
