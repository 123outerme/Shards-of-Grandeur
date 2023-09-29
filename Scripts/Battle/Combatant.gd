extends Resource
class_name Combatant

@export_category("Combatant - Presentation")
@export var sprite: Texture2D = null
@export var displayName: String = ''
@export var saveName: String = ''

@export_category("Combatant - Stats")
@export var stats: Stats = Stats.new()
@export var statChanges: StatChanges = StatChanges.new()
@export var statusEffect: StatusEffect = null

func _init(
	i_sprite = null,
	i_displayName = '',
	i_saveName = '',
	i_stats = Stats.new(),
	i_statChanges = StatChanges.new(),
	i_statusEffect = null,
):
	sprite = i_sprite
	displayName = i_displayName
	saveName = i_saveName
	stats = i_stats
	statChanges = i_statChanges
	statusEffect = i_statusEffect
